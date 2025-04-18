import Foundation
import UIKit
import CryptoKit

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
            let hash = self.hashSHA256(str: hashString)
            
            // Usage:
            let inputTest = "iOS-18.4-430x932-188.190.179.192"
            let hashTest = self.hashSHA256(str: inputTest)
            print(hashTest)
            
            
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
    func hashSHA256(str: String) -> String {
        let inputData = Data(str.utf8)
        let hashed = SHA256.hash(data: inputData)
        
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
