import UIKit

public struct ValidConfig: Codable {
    public let imageFormat: String
    public let skipAntispoof: Bool
    
    public init(imageFormat: String = "rgba",
         skipAntispoof: Bool = true) {
        self.imageFormat = imageFormat
        self.skipAntispoof = skipAntispoof
    }
    
    enum CodingKeys: String, CodingKey {
        case imageFormat = "input_image_format"
        case skipAntispoof = "skip_antispoof"
    }
}

public struct EstimageAgeConfig: Codable {
    public let imageFormat: String
    public let skipAntispoof: Bool
    
    public init(imageFormat: String = "rgba",
         skipAntispoof: Bool = true) {
        self.imageFormat = imageFormat
        self.skipAntispoof = skipAntispoof
    }
    
    enum CodingKeys: String, CodingKey {
        case imageFormat = "input_image_format"
        case skipAntispoof = "skip_antispoof"
    }
}

public struct PredictConfig: Codable {
    public let imageFormat: String
    public let skipAntispoof: Bool
    public let mfToken: String?
    public let antiSpoofingThreshold: Double
    public let thresholdUserTooClose: Double
    public let thresholdUserTooFar: Double
    public let thresholdUserRight: Double
    public let thresholdUserLeft: Double
    public let thresholdDownVerticalPredict: Double
    public let thresholdHighVerticalPredict: Double
    public let thresholdProfilePredict: Double
    public let mfCountOverride: Double
    
    public init(imageFormat: String = "rgba",
                skipAntispoof: Bool = true, mfToken: String? = nil,
                antiSpoofingThreshold: Double = 0.75,
                thresholdUserTooClose: Double = 0.8,
                thresholdUserTooFar: Double = 0.1,
                thresholdUserRight: Double = 0.01,
                thresholdUserLeft: Double = 0.99,
                thresholdDownVerticalPredict: Double = 0.7,
                thresholdHighVerticalPredict: Double = -0.1,
                thresholdProfilePredict: Double = 0.7,
                mfCountOverride: Double = 3) {
        self.imageFormat = imageFormat
        self.skipAntispoof = skipAntispoof
        self.mfToken = mfToken
        self.antiSpoofingThreshold = antiSpoofingThreshold
        self.thresholdUserTooClose = thresholdUserTooClose
        self.thresholdUserTooFar = thresholdUserTooFar
        self.thresholdUserRight = thresholdUserRight
        self.thresholdUserLeft = thresholdUserLeft
        self.thresholdDownVerticalPredict = thresholdDownVerticalPredict
        self.thresholdHighVerticalPredict = thresholdHighVerticalPredict
        self.thresholdProfilePredict = thresholdProfilePredict
        self.mfCountOverride = mfCountOverride
    }
    
    enum CodingKeys: String, CodingKey {
        case imageFormat = "input_image_format"
        case skipAntispoof = "skip_antispoof"
        case mfToken = "mf_token"
        case antiSpoofingThreshold = "anti_spoofing_threshold"
        case thresholdUserTooClose = "threshold_user_too_close"
        case thresholdUserTooFar = "threshold_user_too_far"
        case thresholdUserRight = "threshold_user_right"
        case thresholdUserLeft = "threshold_user_left"
        case thresholdDownVerticalPredict = "threshold_down_vertical_predict"
        case thresholdHighVerticalPredict = "threshold_high_vertical_predict"
        case thresholdProfilePredict = "threshold_profile_predict"
        case mfCountOverride = "mf_count_override"
    }
}

public struct EnrollConfig: Codable {
    public let imageFormat: String
    public let mfToken: String?
    public let skipAntispoof: Bool
    public let disableEnrollMF: Bool
    public let thresholdUserTooFar: Double
    public let thresholdUserTooClose: Double
    public let thresholdUserRight: Double
    public let thresholdUserLeft: Double
    public let thresholdProfileEnroll: Double
    
    public init(imageFormat: String = "rgba",
                mfToken: String? = nil,
                skipAntispoof: Bool = true,
                disableEnrollMF: Bool = false,
                thresholdUserTooFar: Double = 0.31,
                thresholdUserTooClose: Double = 0.55,
                thresholdUserRight: Double = 0.2,
                thresholdUserLeft: Double = 0.8,
                thresholdProfileEnroll: Double = 0.66) {
        self.imageFormat = imageFormat
        self.mfToken = mfToken
        self.skipAntispoof = skipAntispoof
        self.disableEnrollMF = disableEnrollMF
        self.thresholdUserTooFar = thresholdUserTooFar
        self.thresholdUserTooClose = thresholdUserTooClose
        self.thresholdUserRight = thresholdUserRight
        self.thresholdUserLeft = thresholdUserLeft
        self.thresholdProfileEnroll = thresholdProfileEnroll
    }
    
    enum CodingKeys: String, CodingKey {
        case imageFormat = "input_image_format"
        case skipAntispoof = "skip_antispoof"
        case mfToken = "mf_token"
        case disableEnrollMF = "disable_enroll_mf"
        case thresholdUserTooFar = "threshold_user_too_far"
        case thresholdUserTooClose = "threshold_user_too_close"
        case thresholdUserRight = "threshold_user_right"
        case thresholdUserLeft = "threshold_user_left"
        case thresholdProfileEnroll = "threshold_profile_enroll"
    }
}

public struct DocumentFrontScanConfig: Codable {
    public let imageFormat: String
    public let skipAntispoof: Bool
    
    public init(imageFormat: String = "rgba",
         skipAntispoof: Bool = true) {
        self.imageFormat = imageFormat
        self.skipAntispoof = skipAntispoof
    }
    
    enum CodingKeys: String, CodingKey {
        case imageFormat = "input_image_format"
        case skipAntispoof = "skip_antispoof"
    }
}

public struct DocumentBackScanConfig: Codable {
    public let imageFormat: String
    public let skipAntispoof: Bool
    public let documentScanBarcodeOnly: Bool
    
    public init(imageFormat: String = "rgba",
         skipAntispoof: Bool = true,
         documentScanBarcodeOnly: Bool = true) {
        self.imageFormat = imageFormat
        self.skipAntispoof = skipAntispoof
        self.documentScanBarcodeOnly = documentScanBarcodeOnly
    }
    
    enum CodingKeys: String, CodingKey {
        case imageFormat = "input_image_format"
        case skipAntispoof = "skip_antispoof"
        case documentScanBarcodeOnly = "document_scan_barcode_only"
    }
}

public struct DocumentFrontScanAndSelfieConfig: Codable {
    public let imageFormat: String
    public let skipAntispoof: Bool
    
    public init(imageFormat: String = "rgba",
         skipAntispoof: Bool = true) {
        self.imageFormat = imageFormat
        self.skipAntispoof = skipAntispoof
    }
    
    enum CodingKeys: String, CodingKey {
        case imageFormat = "input_image_format"
        case skipAntispoof = "skip_antispoof"
    }
}

public struct CompareEmbeddingsConfig: Codable {
    // TODO:
}
