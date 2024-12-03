import UIKit
import ProgressHUD

final class CryptonetManager {
    
    static let shared = CryptonetManager()
    
    var cryptonet: CryptonetPackage?
    
    var sessionToken: String?
    var publicKey: String?
    var selectedBrowser: String?
    var redirectURL: String?

    private init() { }
    
    func resetSession() {
        CryptonetManager.shared.sessionToken = nil
    }
}
