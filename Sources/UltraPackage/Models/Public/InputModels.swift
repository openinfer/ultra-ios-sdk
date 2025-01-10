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
