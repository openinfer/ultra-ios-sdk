import UIKit
import privid_fhe_uber

enum CryptonetError: Error {
    case noJSON
    case failed
}

public class CryptonetPackage {
    
    public init() {}
    
    private var sessionPointer: UnsafeMutableRawPointer?
    
    public var version: String {
        let version = String(cString: privid_get_version(), encoding: .utf8)
        return version ?? ""
    }
    
    public func initializeLib(path: NSString) {
        privid_initialize_lib(UnsafeMutablePointer<CChar>(mutating: path.utf8String), Int32(path.length))
    }
    
    public func initializeSession(settings: NSString) -> Bool {
        let settingsPointer = UnsafeMutablePointer<CChar>(mutating: settings.utf8String)
        let sessionPointer = UnsafeMutablePointer<UnsafeMutableRawPointer?>.allocate(capacity: 1)

        let isDone = privid_initialize_session(settingsPointer,
                                               UInt32(settings.length),
                                               sessionPointer)

        self.sessionPointer = sessionPointer.pointee
        return isDone
    }
    
    public func deinitializeSession() -> Result<Bool, Error> {
        guard let sessionPointer = self.sessionPointer else {
            return .failure(CryptonetError.failed)
        }
        
        privid_deinitialize_session(sessionPointer)
        return .success(true)
    }
    
    public func enroll(image: UIImage, config: EnrollConfig) -> Result<String, Error> {
        guard let sessionPointer = self.sessionPointer,
              let resized = image.resizeImage(targetSize: CGSize(width: 1000, height: 1000)),
              let cgImage = resized.cgImage else {
            return .failure(CryptonetError.failed)
        }
        
        do {
            let configData = try JSONEncoder().encode(config)
            let userConfig = NSString(string: String(data: configData, encoding: .utf8)!)
            let byteImageArray = convertImageToRgbaRawBitmap(image: cgImage)

            let imageWidth = Int32(resized.size.width)
            let imageHeight = Int32(resized.size.height)

            let userConfigPointer = UnsafeMutablePointer<CChar>(mutating: userConfig.utf8String)

            let bufferOut = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: 1)
            let lengthOut = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
            
            let _ = privid_user_enroll(sessionPointer,
                                        userConfigPointer,
                                        Int32(userConfig.length),
                                        byteImageArray,
                                        imageWidth,
                                        imageHeight,
                                        bufferOut,
                                        lengthOut)

            let outputString = convertToNSString(pointer: bufferOut)
            
            privid_free_char_buffer(bufferOut.pointee)
            
            bufferOut.deallocate()
            lengthOut.deallocate()
            
            guard let outputString = outputString else { return .failure(CryptonetError.noJSON) }
            return .success(outputString)
        } catch {
            return .failure(CryptonetError.failed)
        }
    }
    
    public func predict(image: UIImage, config: PredictConfig) -> Result<String, Error> {
        guard let sessionPointer = self.sessionPointer,
              let resized = image.resizeImage(targetSize: CGSize(width: 1000, height: 1000)),
              let cgImage = resized.cgImage else {
            return .failure(CryptonetError.failed)
        }
        
        do {
            let configData = try JSONEncoder().encode(config)
            let userConfig = NSString(string: String(data: configData, encoding: .utf8)!)
            let byteImageArray = convertImageToRgbaRawBitmap(image: cgImage)

            let imageWidth = Int32(resized.size.width)
            let imageHeight = Int32(resized.size.height)
            
            let userConfigPointer = UnsafeMutablePointer<CChar>(mutating: userConfig.utf8String)
            
            let bufferOut = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: 1)
            let lengthOut = UnsafeMutablePointer<Int32>.allocate(capacity: 1)
            
            let _ = privid_user_predict(sessionPointer,
                                              userConfigPointer,
                                              Int32(userConfig.length),
                                              byteImageArray,
                                              imageWidth,
                                              imageHeight,
                                              bufferOut,
                                              lengthOut)

            let outputString = convertToNSString(pointer: bufferOut)
            
            privid_free_char_buffer(bufferOut.pointee)
            
            bufferOut.deallocate()
            lengthOut.deallocate()
            
            guard let outputString = outputString else { return .failure(CryptonetError.noJSON) }
            return .success(outputString)
        } catch {
            return .failure(CryptonetError.failed)
        }
    }
    
    public func compareEmbeddings(embeddingsOne: [UInt8], embeddingsTwo: [UInt8]) -> Result<String, Error> {
        guard let sessionPointer = self.sessionPointer else {
            return .failure(CryptonetError.failed)
        }

        let userConfig = NSString(string: "{}")
        let userConfigPointer = UnsafeMutablePointer<CChar>(mutating: userConfig.utf8String)
        
        let bufferOne = UnsafeMutablePointer<UInt8>.allocate(capacity: embeddingsOne.count)
        bufferOne.initialize(from: embeddingsOne, count: embeddingsOne.count)
        
        let bufferTwo = UnsafeMutablePointer<UInt8>.allocate(capacity: embeddingsTwo.count)
        bufferTwo.initialize(from: embeddingsTwo, count: embeddingsTwo.count)
        
        let bufferOut = UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>.allocate(capacity: 1)
        let lengthOut = UnsafeMutablePointer<Int32>.allocate(capacity: 1)

        let _ = privid_compare_embeddings(sessionPointer,
                                userConfigPointer,
                                Int32(userConfig.length),
                                bufferOne,
                                Int32(embeddingsOne.count),
                                bufferTwo,
                                Int32(embeddingsTwo.count),
                                bufferOut,
                                lengthOut)
        let outputString = convertToNSString(pointer: bufferOut)
        
        privid_free_char_buffer(bufferOut.pointee)
        
        bufferOut.deallocate()
        lengthOut.deallocate()
        
        guard let outputString = outputString else { return .failure(CryptonetError.noJSON) }
        return .success(outputString)
    }
}

private extension CryptonetPackage {
    func convertImageToRgbaRawBitmap(image: CGImage) -> [UInt8] {
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        
        var rawData = [UInt8](repeating: 0, count: image.width * image.height * bytesPerPixel)
        
        let context = CGContext(
            data: &rawData, width: image.width, height: image.height,
            bitsPerComponent: bitsPerComponent, bytesPerRow: image.width * bytesPerPixel,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
        
        context?.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))
        
        return rawData
    }

    func convertToNSString(pointer: UnsafeMutablePointer<UnsafeMutablePointer<CChar>?>) -> String? {
        guard let cStringPointer = pointer.pointee else { return nil }
        return String(NSString(utf8String: cStringPointer) ?? "")
    }
}
