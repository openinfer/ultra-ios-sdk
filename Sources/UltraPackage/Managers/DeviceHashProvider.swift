import Foundation
import UIKit
import CommonCrypto

class DeviceHashProvider {
    private let systemName = "iOS"
    private let unknownSystemName = "Unknown"
    private let messageDigestAlg = "SHA256"
    
    /**
     * Generates a unique SHA-256 hash representing the current device's key characteristics.
     *
     * The hash is computed from the following components:
     * - System name (iOS)
     * - iOS version
     * - Screen resolution in points (width x height)
     * - Public IP address (if retrievable)
     */
    func getDeviceHash(completion: @escaping (String) -> Void) {
        let screenSize = UIScreen.main.bounds.size
        let screenWidth = Int(screenSize.width)
        let screenHeight = Int(screenSize.height)
        
        getPublicIpAddress { ipAddress in
            let components = [
                self.systemName,
                UIDevice.current.systemVersion,
                "\(screenWidth)x\(screenHeight)",
                ipAddress ?? "unknown"
            ]
            
            let hashString = components.joined(separator: "-")
            let hash = self.hashSHA256(input: hashString)
            completion(hash)
        }
    }
    
    /**
     * Retrieves the device's public IP address by making a network request.
     */
    private func getPublicIpAddress(completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "https://api.ipify.org?format=json") else {
            completion(nil)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let ip = json["ip"] as? String {
                    completion(ip)
                } else {
                    completion(nil)
                }
            } catch {
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    /**
     * Computes the SHA-256 hash of the given input string.
     */
    private func hashSHA256(input: String) -> String {
        guard let data = input.data(using: .utf8) else { return "" }
        
        var hash = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        data.withUnsafeBytes { buffer in
            _ = CC_SHA256(buffer.baseAddress, CC_LONG(buffer.count), &hash)
        }
        
        return hash.map { String(format: "%02x", $0) }.joined()
    }
}
