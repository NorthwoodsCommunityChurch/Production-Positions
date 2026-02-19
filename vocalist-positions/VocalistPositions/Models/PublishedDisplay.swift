import Foundation

/// The full data structure served to the web display.
struct PublishedDisplay: Codable {
    let serviceName: String
    let serviceDate: Date
    let vocalists: [DisplayVocalist]

    struct DisplayVocalist: Codable {
        let number: Int
        let label: String?
        let anglePhotoFilename: String?
        let operatorName: String?
        let operatorPhotoFilename: String?
    }
}
