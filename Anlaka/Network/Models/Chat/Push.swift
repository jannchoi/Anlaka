import Foundation

struct PushRequestDTO: Codable {
    let user_ids: [String]
    let title: String
    let subtitle: String?
    let body: String
}
