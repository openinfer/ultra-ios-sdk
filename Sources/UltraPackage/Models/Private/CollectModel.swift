import Foundation

struct CollectModel: Codable {
    let callStatus: CollectCallStatus?
    let uberOperationResult: CollectUberOperationResult?

    enum CodingKeys: String, CodingKey {
        case callStatus = "call_status"
        case uberOperationResult = "uber_operation_result"
    }
}

struct CollectCallStatus: Codable {
    let returnStatus: Int?
    let operationTag, returnMessage, mfToken: String?
    let operationID, operationTypeID: Int?

    enum CodingKeys: String, CodingKey {
        case returnStatus = "return_status"
        case operationTag = "operation_tag"
        case returnMessage = "return_message"
        case mfToken = "mf_token"
        case operationID = "operation_id"
        case operationTypeID = "operation_type_id"
    }
}

// MARK: - UberOperationResult
struct CollectUberOperationResult: Codable {
    let request: CollectRequest?
}

// MARK: - Request
struct CollectRequest: Codable {
    let encryptedKey, encryptedMessage, gcmAad, gcmTag: String?
    let iv: String?
}
