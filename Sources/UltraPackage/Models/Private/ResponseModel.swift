import Foundation

struct ResponseModel: Decodable {
    let statusCode: Int?
    let sessionId: String?
    let publicKey: String?
    let success: Bool?
    let type: String?
    let status: String?
    let redirectURL: String?
}

