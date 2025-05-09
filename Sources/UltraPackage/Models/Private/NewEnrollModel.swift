import Foundation

struct NewEnrollModel: Codable {
    let callStatus: CallStatus?
    let enrollOnefa: EnrollOnefa?
    let uberOperationResult: UberOperationResult?

    enum CodingKeys: String, CodingKey {
        case callStatus = "call_status"
        case enrollOnefa = "enroll_onefa"
        case uberOperationResult = "uber_operation_result"
    }
}

struct CallStatus: Codable {
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

struct EnrollOnefa: Codable {
    let message: String?
    let bestFaceImage: EnrollBestFaceImage?
    let apiResponse: EnrollAPIResponse?
    let faceValidationData: FaceValidationData?
    let encryptedEmbeddings: String?
    let enrollPerformed: Bool?

    enum CodingKeys: String, CodingKey {
        case message
         case faceValidationData = "face_validation_data"
         case bestFaceImage = "best_face_image"
         case apiResponse = "api_response"
         case encryptedEmbeddings = "encrypted_embeddings"
         case enrollPerformed = "enroll_performed"
    }
}

struct UberOperationResult: Codable {
    let face: FaceValidationData?
    let response: [String?]?
    let embedding: String?
}

struct PredictNewModel: Codable {
    let callStatus: CallStatus?
    let predictOnefa: EnrollOnefa?

    enum CodingKeys: String, CodingKey {
        case callStatus = "call_status"
        case predictOnefa = "predict_onefa"
    }
}

struct EnrollBestFaceImage: Codable {
    let info: EnrollInfo?
    let data: String?
}

// MARK: - Info
struct EnrollInfo: Codable {
    let width, height, channels, depths: Double?
    let color: Double?
}

struct EnrollAPIResponse: Codable {
    let status, enrollLevel: Int?
    let guid, puid, message: String?

    enum CodingKeys: String, CodingKey {
        case status
        case enrollLevel = "enroll_level"
        case guid, puid, message
    }
}

struct FaceValidationData: Codable {
    let faceValidationStatus: Int?
    let boundingBox: BoundingBox?
    let eyeLeft, eyeRight: EyeLeft?
    let faceConfidenceScore: Double?
    let antispoofingStatus: Int?

    enum CodingKeys: String, CodingKey {
        case faceValidationStatus = "face_validation_status"
        case boundingBox = "bounding_box"
        case eyeLeft = "eye_left"
        case eyeRight = "eye_right"
        case faceConfidenceScore = "face_confidence_score"
        case antispoofingStatus = "antispoofing_status"
    }
}

// MARK: - Response
struct Response: Codable {
    let success: Bool?
    let gcmAad, gcmTag, encryptedMessage, encryptedKey, iv: String?
}

struct BoundingBox: Codable {
    let topLeft, bottomRight: EyeLeft?

    enum CodingKeys: String, CodingKey {
        case topLeft = "top_left"
        case bottomRight = "bottom_right"
    }
}

// MARK: - EyeLeft
struct EyeLeft: Codable {
    let x: Double?
    let y: Double?
}
