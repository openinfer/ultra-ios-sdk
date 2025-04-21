import Foundation

struct ResponseModel: Decodable {
    let statusCode: Int?
    let sessionId: String?
    let publicKey: String?
    let success: Bool?
    let type: String?
    let status: String?
    let redirectURL: String?
    let config: ResponseConfig?
}

// MARK: - Config
struct ResponseConfig: Codable {
    let sessionDuration, biometricDuration: Double?
    let browser, universalLink: String?
}
