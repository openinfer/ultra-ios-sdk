import Foundation

struct SessionDetailsModel: Codable {
    let sessionID, status: String?
    let identificationResult: IdentificationResult?
    let deviceVerificationResult: DeviceVerificationResult?

    enum CodingKeys: String, CodingKey {
        case sessionID = "sessionId"
        case status, identificationResult, deviceVerificationResult
    }
}

// MARK: - IdentificationResult
struct IdentificationResult: Codable {
    let uuid: String?
    let confidence: Double?
    let status: String?
    let topKMatches: [TopKMatch]?
}

// MARK: - DeviceVerificationResult
struct DeviceVerificationResult: Codable {
    let status: String?
}

// MARK: - TopKMatch
struct TopKMatch: Codable {
    let confidence: Double?
    let uuid: String?
}

