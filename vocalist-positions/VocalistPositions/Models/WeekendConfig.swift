import Foundation

struct WeekendConfig: Codable, Identifiable {
    let id: UUID
    var pcoServicePlanId: String?
    var serviceDate: Date
    var serviceName: String
    var assignments: [VocalistAssignment]

    init(
        id: UUID = UUID(),
        pcoServicePlanId: String? = nil,
        serviceDate: Date,
        serviceName: String,
        assignments: [VocalistAssignment] = []
    ) {
        self.id = id
        self.pcoServicePlanId = pcoServicePlanId
        self.serviceDate = serviceDate
        self.serviceName = serviceName
        self.assignments = assignments
    }
}
