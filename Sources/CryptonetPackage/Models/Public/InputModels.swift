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
    
    public init(imageFormat: String = "rgba",
         skipAntispoof: Bool = true, mfToken: String? = nil) {
        self.imageFormat = imageFormat
        self.skipAntispoof = skipAntispoof
        self.mfToken = mfToken
    }
    
    enum CodingKeys: String, CodingKey {
        case imageFormat = "input_image_format"
        case skipAntispoof = "skip_antispoof"
        case mfToken = "mf_token"
    }
}

public struct EnrollConfig: Codable {
    public let imageFormat: String
    public let mfToken: String?
    public let skipAntispoof: Bool
    public let disableEnrollMF: Bool
    
    public init(imageFormat: String = "rgba",
         mfToken: String? = nil,
         skipAntispoof: Bool = true,
         disableEnrollMF: Bool = false) {
        self.imageFormat = imageFormat
        self.mfToken = mfToken
        self.skipAntispoof = skipAntispoof
        self.disableEnrollMF = disableEnrollMF
    }
    
    enum CodingKeys: String, CodingKey {
        case imageFormat = "input_image_format"
        case skipAntispoof = "skip_antispoof"
        case mfToken = "mf_token"
        case disableEnrollMF = "disable_enroll_mf"
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
