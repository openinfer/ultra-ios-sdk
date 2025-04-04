import UIKit
import ProgressHUD

enum CryptonetError: Error {
    case noJSON
    case failed
}

public class UltraPackage {
    
    private var sessionPointer: UnsafeMutableRawPointer?
    private var startedType: NetworkManager.SessionFlow?
    
    public init() {}
    
    public func start(path: String,
                      token: String?,
                      publicKey: String?,
                      browser: String?,
                      universalLink: String?,
                      type: NetworkManager.SessionFlow = NetworkManager.SessionFlow.predict,
                      securityModel: SecurityModel,
                      finished: @escaping (Bool) -> Void) {
        
        CryptonetManager.shared.initializeLib(path: NSString(string: path))
        CryptonetManager.shared.selectedBrowser = browser ?? "chrome"
        CryptonetManager.shared.universalLink = universalLink
        
        self.startedType = type
        print("VERSION: - \(CryptonetManager.shared.version())")
        
        NetworkManager.shared.getSessionToken(type: type) { newToken in
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
                  "session_token": "\(finalToken)",
                  "debug_level": "3"
                }
                """
                
                let securityCheck = self.checkSecurityConditions(securityModel: securityModel)
                let result = CryptonetManager.shared.initializeSession(settings: NSString(string: settings))
                finished(result && securityCheck)
            }
        }
    }
    
    public func runVisual(on viewController: UIViewController) {
        guard let startedType = startedType else {
            ProgressHUD.failed("Started type is empty")
            return
        }
        switch startedType {
        case .enroll:
            NetworkManager.shared.checkFlowStatus { _ in
                let storyboard = UIStoryboard(name: "InstructionsViewController", bundle: Bundle.module)
                let vc = storyboard.instantiateViewController(withIdentifier: "MainInstructionsViewController")
                viewController.navigationController?.pushViewController(vc, animated: true)
            }
        case .predict:
            NetworkManager.shared.checkFlowStatus { _ in
                self.runPredictWithFaceId(on: viewController)
            }
        }
    }
    
    func checkSecurityConditions(securityModel: SecurityModel) -> Bool {
        return true
        /*
        return securityModel.model == UIDevice.current.model &&
        securityModel.sceenBounds == UIScreen.main.bounds &&
        securityModel.orientation == UIDevice.current.orientation &&
        securityModel.processorCount == ProcessInfo().processorCount &&
        securityModel.battertLevel == UIDevice.current.batteryLevel &&
        securityModel.languageCode == Locale.current.languageCode
         */
    }
    
    private func runPredictWithFaceId(on viewController: UIViewController) {
        let storyboard = UIStoryboard(name: "ScanViewController", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "MainScanViewController")
        viewController.navigationController?.pushViewController(vc, animated: true)
    }
}
