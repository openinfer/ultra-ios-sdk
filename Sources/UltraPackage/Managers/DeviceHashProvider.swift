import Foundation
import UIKit
import CryptoKit

class DeviceHashProvider {
    private let systemName = "iOS"
    
    /**
     * Generates a unique SHA-256 hash representing the current device's key characteristics.
     *
     * The hash is computed from the following components in order:
     * - System name (iOS)
     * - iOS version
     * - Screen resolution in points (width x height)
     * - Timezone (GMT format)
     * - Language identifier
     * - Screen scale (device pixel ratio)
     */
    func getDeviceHash(completion: @escaping (String) -> Void) {
        let screenSize = UIScreen.main.bounds.size
        let screenWidth = Int(screenSize.width)
        let screenHeight = Int(screenSize.height)
        
        // Get timezone in GMT format
        let timeZone = Calendar.current.timeZone
        let offsetSeconds = timeZone.secondsFromGMT()
        let offsetHours = offsetSeconds / 3600
        let timeZoneString = "GMT\(offsetHours >= 0 ? "+" : "")\(offsetHours)"
        
        // Get language identifier (e.g. "en-US")
        let languageId = Locale.current.identifier
        
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
        let hash = self.hashSHA256(str: hashString)
        completion(hash)
    }
    
    /**
     * Computes the SHA-256 hash of the given input string.
     */
    func hashSHA256(str: String) -> String {
        let cleanedInput = str.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let inputData = cleanedInput.data(using: .utf8) else {
            return ""
        }
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
