import Foundation
import Observation
import OSLog

private let logger = Logger(subsystem: "com.northwoods.VocalistPositions", category: "AppViewModel")

@Observable
final class AppViewModel {
    // MARK: - State

    var vocalistPositions: [VocalistPosition] = []
    var weekends: [WeekendConfig] = []
    var selectedWeekendId: UUID?

    // Editing state: the in-progress assignments for the selected weekend
    var workingAssignments: [VocalistAssignment] = []

    // PCO team members for the selected weekend
    var teamMembers: [TeamMember] = []

    // Person photos: maps person name → local photo filename
    var personPhotos: [String: String] = [:]

    // MARK: - Services

    let persistence: PersistenceService
    let imageStorage: ImageStorage
    let displayServer: DisplayServer
    let pcoAuth: PCOAuthService
    let pcoAPI: PCOAPIClient

    // PCO configuration
    var selectedServiceTypeId: String? {
        didSet { UserDefaults.standard.set(selectedServiceTypeId, forKey: "pco_service_type_id") }
    }
    var selectedTeamId: String? {
        didSet { UserDefaults.standard.set(selectedTeamId, forKey: "pco_team_id") }
    }
    var pcoServiceTypes: [PCOAPIClient.ServiceType] = []
    var pcoTeams: [PCOAPIClient.Team] = []
    var pcoError: String?

    init() {
        let persistence = PersistenceService()
        let imageStorage = ImageStorage()
        let pcoAuth = PCOAuthService()
        self.persistence = persistence
        self.imageStorage = imageStorage
        self.displayServer = DisplayServer(persistence: persistence, imageStorage: imageStorage)
        self.pcoAuth = pcoAuth
        self.pcoAPI = PCOAPIClient(authService: pcoAuth)
        self.selectedServiceTypeId = UserDefaults.standard.string(forKey: "pco_service_type_id")
        self.selectedTeamId = UserDefaults.standard.string(forKey: "pco_team_id")
    }

    // MARK: - Computed

    var selectedWeekend: WeekendConfig? {
        guard let id = selectedWeekendId else { return nil }
        return weekends.first { $0.id == id }
    }

    // MARK: - Initialization

    func loadData() {
        vocalistPositions = persistence.loadVocalistPositions()
        weekends = persistence.loadAllWeekendConfigs()
        personPhotos = persistence.loadPersonPhotos()

        // Create a default weekend if none exist and PCO isn't connected
        if weekends.isEmpty && !pcoAuth.isAuthenticated {
            let thisWeekend = WeekendConfig(
                serviceDate: nextSunday(),
                serviceName: "This Weekend"
            )
            weekends.append(thisWeekend)
            persistence.saveWeekendConfig(thisWeekend)
        }

        // Create default vocalist positions if none exist
        if vocalistPositions.isEmpty {
            for i in 1...5 {
                vocalistPositions.append(VocalistPosition(number: i))
            }
            persistence.saveVocalistPositions(vocalistPositions)
        }

        // Auto-select first weekend
        if selectedWeekendId == nil {
            selectedWeekendId = weekends.first?.id
        }

        loadWorkingAssignments()

        // Publish current state so the web display is fresh on startup
        autoPublish()

        // Start the web display server
        displayServer.start()

        // Load PCO data if already authenticated
        if pcoAuth.isAuthenticated {
            Task { await loadPCOData() }
        }
    }

    // MARK: - Weekend Selection

    func selectWeekend(_ id: UUID) {
        selectedWeekendId = id
        loadWorkingAssignments()
        autoPublish()
    }

    private func loadWorkingAssignments() {
        guard let weekend = selectedWeekend else {
            workingAssignments = []
            return
        }

        // Start with the weekend's saved assignments, filling in blanks for any vocalist positions
        var assignments = weekend.assignments
        for position in vocalistPositions {
            if !assignments.contains(where: { $0.vocalistPositionId == position.id }) {
                assignments.append(VocalistAssignment(vocalistPositionId: position.id))
            }
        }
        workingAssignments = assignments
    }

    // MARK: - Vocalist Position Management

    func addVocalistPosition() {
        let nextNumber = (vocalistPositions.map(\.number).max() ?? 0) + 1
        let position = VocalistPosition(number: nextNumber)
        vocalistPositions.append(position)
        persistence.saveVocalistPositions(vocalistPositions)

        // Add a blank assignment for the new position
        workingAssignments.append(VocalistAssignment(vocalistPositionId: position.id))
        autoPublish()
    }

    func removeVocalistPosition(_ id: UUID) {
        vocalistPositions.removeAll { $0.id == id }
        // Renumber remaining positions
        for i in vocalistPositions.indices {
            vocalistPositions[i].number = i + 1
        }
        persistence.saveVocalistPositions(vocalistPositions)

        workingAssignments.removeAll { $0.vocalistPositionId == id }
        autoPublish()
    }

    func updateVocalistPositionLabel(_ id: UUID, label: String?) {
        guard let index = vocalistPositions.firstIndex(where: { $0.id == id }) else { return }
        vocalistPositions[index].label = label
        persistence.saveVocalistPositions(vocalistPositions)
    }

    func setVocalistAnglePhoto(_ id: UUID, imageData: Data) {
        guard let index = vocalistPositions.firstIndex(where: { $0.id == id }) else { return }

        // Delete old photo if exists
        if let oldFilename = vocalistPositions[index].anglePhotoFilename {
            imageStorage.deleteImage(filename: oldFilename)
        }

        if let filename = imageStorage.saveImage(imageData) {
            vocalistPositions[index].anglePhotoFilename = filename
            persistence.saveVocalistPositions(vocalistPositions)
        }
    }

    // MARK: - Assignment Management (Drag and Drop)

    func assignOperator(to vocalistPositionId: UUID, name: String, pcoId: String? = nil) {
        guard let index = workingAssignments.firstIndex(where: { $0.vocalistPositionId == vocalistPositionId }) else { return }

        // Remove operator from any other assignment first
        for i in workingAssignments.indices {
            if workingAssignments[i].operatorName == name {
                workingAssignments[i].operatorName = nil
                workingAssignments[i].operatorPcoId = nil
            }
        }

        workingAssignments[index].operatorName = name
        workingAssignments[index].operatorPcoId = pcoId
        autoPublish()
    }

    func removeOperator(from vocalistPositionId: UUID) {
        guard let index = workingAssignments.firstIndex(where: { $0.vocalistPositionId == vocalistPositionId }) else { return }
        workingAssignments[index].operatorName = nil
        workingAssignments[index].operatorPcoId = nil
        autoPublish()
    }

    // MARK: - Auto Publish

    /// Saves and publishes to the web display on every change
    func autoPublish() {
        guard var weekend = selectedWeekend,
              let weekendIndex = weekends.firstIndex(where: { $0.id == weekend.id }) else { return }

        weekend.assignments = workingAssignments
        weekends[weekendIndex] = weekend
        persistence.saveWeekendConfig(weekend)

        let display = buildPublishedDisplay(from: weekend)
        persistence.savePublishedDisplay(display)

        logger.info("Auto-published display")
    }

    private func buildPublishedDisplay(from weekend: WeekendConfig) -> PublishedDisplay {
        let displayVocalists = vocalistPositions.map { position -> PublishedDisplay.DisplayVocalist in
            let assignment = workingAssignments.first { $0.vocalistPositionId == position.id }
            // Look up person photo for the assigned operator
            let operatorPhoto: String? = if let name = assignment?.operatorName {
                personPhotos[name]
            } else {
                nil
            }

            return PublishedDisplay.DisplayVocalist(
                number: position.number,
                label: position.label,
                anglePhotoFilename: position.anglePhotoFilename,
                operatorName: assignment?.operatorName,
                operatorPhotoFilename: operatorPhoto
            )
        }

        return PublishedDisplay(
            serviceName: weekend.serviceName,
            serviceDate: weekend.serviceDate,
            vocalists: displayVocalists
        )
    }

    // MARK: - Planning Center

    func pcoConnect(appId: String, secret: String) async {
        pcoAuth.connect(appId: appId, secret: secret)
        await loadPCOData()
    }

    func pcoLogout() {
        pcoAuth.logout()
        pcoServiceTypes = []
        pcoTeams = []
        selectedServiceTypeId = nil
        selectedTeamId = nil
    }

    func loadPCOData() async {
        guard pcoAuth.isAuthenticated else { return }

        do {
            // Fetch service types
            pcoServiceTypes = try await pcoAPI.fetchServiceTypes()

            // Auto-select first service type if none selected
            if selectedServiceTypeId == nil, let first = pcoServiceTypes.first {
                selectedServiceTypeId = first.id
            }

            // Fetch teams for selected service type
            if let stId = selectedServiceTypeId {
                pcoTeams = try await pcoAPI.fetchTeams(serviceTypeId: stId)
            }

            // Fetch upcoming plans
            await loadPCOWeekends()

            pcoError = nil
        } catch {
            pcoError = error.localizedDescription
            logger.error("PCO data fetch failed: \(error.localizedDescription)")
        }
    }

    func loadPCOWeekends() async {
        guard let stId = selectedServiceTypeId else { return }

        do {
            let plans = try await pcoAPI.fetchUpcomingPlans(serviceTypeId: stId)

            // Convert PCO plans to WeekendConfigs
            for plan in plans {
                if let existingIndex = weekends.firstIndex(where: { $0.pcoServicePlanId == plan.id }) {
                    // Update date and name from PCO
                    weekends[existingIndex].serviceDate = plan.sortDate
                    weekends[existingIndex].serviceName = plan.title ?? plan.dates
                    persistence.saveWeekendConfig(weekends[existingIndex])
                } else {
                    let config = WeekendConfig(
                        pcoServicePlanId: plan.id,
                        serviceDate: plan.sortDate,
                        serviceName: plan.title ?? plan.dates
                    )
                    weekends.append(config)
                    persistence.saveWeekendConfig(config)
                }
            }

            // Sort weekends by date
            weekends.sort { $0.serviceDate < $1.serviceDate }

            // Auto-select first if none selected
            if selectedWeekendId == nil {
                selectedWeekendId = weekends.first?.id
                loadWorkingAssignments()
            }

            // Load team members for the selected weekend
            await loadTeamMembersForSelectedWeekend()
        } catch {
            pcoError = error.localizedDescription
        }
    }

    func loadTeamMembersForSelectedWeekend() async {
        guard let stId = selectedServiceTypeId,
              let weekend = selectedWeekend,
              let planId = weekend.pcoServicePlanId else { return }

        do {
            let members = try await pcoAPI.fetchTeamMembers(serviceTypeId: stId, planId: planId)

            // Filter by selected team if one is chosen
            let filtered: [PCOAPIClient.PlanTeamMember]
            if let teamId = selectedTeamId {
                filtered = members.filter { $0.teamId == teamId }
            } else {
                filtered = members
            }

            teamMembers = filtered.map { member in
                TeamMember(
                    id: member.id,
                    name: member.personName,
                    photoURL: member.photoThumbnailURL,
                    photoFilename: personPhotos[member.personName]
                )
            }
        } catch {
            pcoError = error.localizedDescription
        }
    }

    // MARK: - Person Photos

    func setPersonPhoto(name: String, imageData: Data) {
        // Delete old photo if exists
        if let oldFilename = personPhotos[name] {
            imageStorage.deleteImage(filename: oldFilename)
        }

        if let filename = imageStorage.saveImage(imageData) {
            personPhotos[name] = filename
            persistence.savePersonPhotos(personPhotos)

            // Update the team member's local photo
            if let index = teamMembers.firstIndex(where: { $0.name == name }) {
                teamMembers[index] = TeamMember(
                    id: teamMembers[index].id,
                    name: teamMembers[index].name,
                    photoURL: teamMembers[index].photoURL,
                    photoFilename: filename
                )
            }

            autoPublish()
        }
    }

    func removePersonPhoto(name: String) {
        if let filename = personPhotos[name] {
            imageStorage.deleteImage(filename: filename)
        }
        personPhotos.removeValue(forKey: name)
        persistence.savePersonPhotos(personPhotos)

        // Update the team member
        if let index = teamMembers.firstIndex(where: { $0.name == name }) {
            teamMembers[index] = TeamMember(
                id: teamMembers[index].id,
                name: teamMembers[index].name,
                photoURL: teamMembers[index].photoURL,
                photoFilename: nil
            )
        }

        autoPublish()
    }

    // MARK: - Helpers

    private func nextSunday() -> Date {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysUntilSunday = weekday == 1 ? 0 : (8 - weekday)
        return calendar.date(byAdding: .day, value: daysUntilSunday, to: today)!
    }
}

// MARK: - Team Member (for PCO integration, also used for manual entry)

struct TeamMember: Identifiable, Hashable {
    let id: String
    let name: String
    let photoURL: String?
    let photoFilename: String?

    init(id: String = UUID().uuidString, name: String, photoURL: String? = nil, photoFilename: String? = nil) {
        self.id = id
        self.name = name
        self.photoURL = photoURL
        self.photoFilename = photoFilename
    }
}
