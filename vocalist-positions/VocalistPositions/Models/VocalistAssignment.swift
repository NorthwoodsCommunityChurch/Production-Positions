import Foundation

struct VocalistAssignment: Codable, Identifiable {
    let id: UUID
    var vocalistPositionId: UUID
    var operatorName: String?
    var operatorPcoId: String?
    var operatorPhotoURL: String?

    init(
        id: UUID = UUID(),
        vocalistPositionId: UUID,
        operatorName: String? = nil,
        operatorPcoId: String? = nil,
        operatorPhotoURL: String? = nil
    ) {
        self.id = id
        self.vocalistPositionId = vocalistPositionId
        self.operatorName = operatorName
        self.operatorPcoId = operatorPcoId
        self.operatorPhotoURL = operatorPhotoURL
    }
}
