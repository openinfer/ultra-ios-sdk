import UIKit
import ProgressHUD
import CryptonetPackage

final class CryptonetManager {
    
    static let shared = CryptonetManager()
    
    let cryptonet = CryptonetPackage()
    
    var sessionToken: String?
    var publicKey: String?
    var selectedBrowser: String?
    var redirectURL: String?

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
}
