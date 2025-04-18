import Foundation
import UIKit
import CryptoKit

class DeviceHashProvider {
    private let systemName = "iOS"
    
    func getDeviceHash(completion: @escaping (String) -> Void) {
        let screenSize = UIScreen.main.bounds.size
        let screenWidth = Int(screenSize.width)
        let screenHeight = Int(screenSize.height)
        
        // Get timezone in GMT format
        let timeZone = Calendar.current.timeZone
        let offsetSeconds = timeZone.secondsFromGMT()
        let offsetHours = offsetSeconds / 3600
        let timeZoneString = "GMT\(offsetHours >= 0 ? "+" : "")\(offsetHours)"
        
        // Get system language (equivalent to navigator.language)
        let languageId = Locale.preferredLanguages.first ?? "en-US"
        
        // Get screen scale (equivalent to devicePixelRatio)
        let screenScale = Int(UIScreen.main.scale)
        
        let components = [
            self.systemName,
            UIDevice.current.systemVersion,
            "\(screenWidth)x\(screenHeight)",
            timeZoneString,
            languageId,
            "\(screenScale)"
        ]
        
        let hashString = components.joined(separator: "-")
        print("Final hashString: \(hashString)")  // For debugging
        
        let hash = self.hashSHA256(str: hashString)
        completion(hash)
    }
    
    func hashSHA256(str: String) -> String {
        let cleanedInput = str.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let inputData = cleanedInput.data(using: .utf8) else {
            return ""
        }
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
