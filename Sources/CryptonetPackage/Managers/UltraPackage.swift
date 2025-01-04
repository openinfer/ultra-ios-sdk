import UIKit
import ProgressHUD

enum CryptonetError: Error {
    case noJSON
    case failed
}

public class UltraPackage {
    
    private var sessionPointer: UnsafeMutableRawPointer?
    
    public init() {}
    
    public func start(path: String, token: String?, publicKey: String?, browser: String?, securityModel: SecurityModel, finished: @escaping (Bool) -> Void) {
        CryptonetManager.shared.initializeLib(path: NSString(string: path))
        CryptonetManager.shared.selectedBrowser = browser ?? "chrome"
        
        NetworkManager.shared.getSessionToken { newToken in
            guard let newToken = newToken else {
                ProgressHUD.failed("Empty session token")
                finished(false)
                return
            }
            
            CryptonetManager.shared.sessionToken = token ?? newToken
            NetworkManager.shared.getPublicKey { newPublicKey in
                guard let newPublicKey = newPublicKey else {
                    ProgressHUD.failed("Empty public key")
                    finished(false)
                    return
                }
                
                CryptonetManager.shared.publicKey = publicKey ?? newPublicKey
                
                let finalToken = CryptonetManager.shared.sessionToken ?? newToken
                let finalKey = CryptonetManager.shared.publicKey ?? newPublicKey
                
                let settings = """
                {
                  "collections": {
                    "default": {
                      "named_urls": {
                        "base_url": "\(NetworkManager.shared.baseURL)v2/verification-session" } } },
                  "public_key": "\(finalKey)",
                  "session_token": "\(finalToken)"
                }
                """
                
                let securityCheck = self.checkSecurityConditions(securityModel: securityModel)
                let result = CryptonetManager.shared.initializeSession(settings: NSString(string: settings))
                finished(result && securityCheck)
            }
        }
    }
    
    public func runVisual(on viewController: UIViewController) {
        let storyboard = UIStoryboard(name: "CryptonetVisual", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "InstructionsViewController")
        viewController.navigationController?.pushViewController(vc, animated: true)
    }
    
    func checkSecurityConditions(securityModel: SecurityModel) -> Bool {
        return securityModel.model == UIDevice.current.model &&
        securityModel.sceenBounds == UIScreen.main.bounds &&
        securityModel.orientation == UIDevice.current.orientation &&
        securityModel.processorCount == ProcessInfo().processorCount &&
        securityModel.battertLevel == UIDevice.current.batteryLevel &&
        securityModel.languageCode == Locale.current.languageCode
    }
}
