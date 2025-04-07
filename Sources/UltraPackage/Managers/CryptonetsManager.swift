import UIKit
import ProgressHUD
import CryptonetPackage
import LocalAuthentication

final class CryptonetManager {
    
    static let shared = CryptonetManager()
    
    let cryptonet = CryptonetPackage()
    private let deviceInfoManager = DeviceInfoManager()
    
    var sessionToken: String?
    var publicKey: String?
    var selectedBrowser: String?
    var redirectURL: String?
    var universalLink: String?
    
    var deeplinkData: DeeplinkData?
    
    static let privacyURL = "https://privateid.uberverify.com/privacy-policy"
    static let termsURL = "https://privateid.uberverify.com/terms"
    static let learnURL = "https://privateid.uberverify.com/values-privacy"
    
    private let isPermissionAcceptedIdentifier = "isPermissionAcceptedIdentifier"

    private init() { }
    
    func initializeLib(path: NSString) {
        cryptonet.initializeLib(path: path)
    }

    func initializeSession(settings: NSString) -> Bool {
        return cryptonet.initializeSession(settings: settings)
    }
    
    func version() -> String {
        return cryptonet.version
    }
    
    func resetSession() {
        CryptonetManager.shared.sessionToken = nil
    }
    
    func authenticateWithFaceIDWithoutPasscode(completion: @escaping (Bool, Error?) -> Void) {
        if isFaceIDAvailableWithoutPasscode() {
            let context = LAContext()
            context.localizedCancelTitle = "Cancel"
            context.interactionNotAllowed = false  // Set to true if you want silent authentication (no UI)

            let reason = "Authenticate using Face ID."

            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason) { success, error in
                DispatchQueue.main.async {
                    completion(success, error)
                }
            }
        } else {
            completion(true, nil)
        }
    }
    
    func startDeviceInfoCollect(with cameraLunchTime: String) {
        deviceInfoManager.start(with: cameraLunchTime)
    }
    
    func getDeviceInfo() -> String? {
        let jsonData = deviceInfoManager.collectDeviceInformation()

        if let jsonDataEncoded = try? JSONSerialization.data(withJSONObject: jsonData, options: .prettyPrinted),
           let jsonString = String(data: jsonDataEncoded, encoding: .utf8) {
           return jsonString
        } else {
            return nil
        }
    }
    
    func isPermissionAccepted() -> Bool {
        return UserDefaults.standard.bool(forKey: isPermissionAcceptedIdentifier)
    }
    
    func askPermissionImplemented() {
       UserDefaults.standard.set(true, forKey: isPermissionAcceptedIdentifier)
    }
    
    private func isFaceIDAvailableWithoutPasscode() -> Bool {
        let context = LAContext()
        var error: NSError?

        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            return context.biometryType == .faceID
        }
        return false
    }
}
