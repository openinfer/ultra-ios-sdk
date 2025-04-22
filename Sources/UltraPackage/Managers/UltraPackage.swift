import UIKit
import ProgressHUD

enum CryptonetError: Error {
    case noJSON
    case failed
}

public class UltraPackage {
    
    private var sessionPointer: UnsafeMutableRawPointer?
    private var defaultStartedType: NetworkManager.SessionFlow?
    
    public init() {}
    
    public func start(path: String,
                      deeplinkData: DeeplinkData?,
                      type: NetworkManager.SessionFlow = NetworkManager.SessionFlow.predict,
                      securityModel: SecurityModel,
                      finished: @escaping (Bool) -> Void) {
        
        CryptonetManager.shared.initializeLib(path: NSString(string: path))
        CryptonetManager.shared.selectedBrowser = deeplinkData?.selectedBrowser ?? "chrome"
        CryptonetManager.shared.universalLink = deeplinkData?.universalLink
        CryptonetManager.shared.sessionDuration = deeplinkData?.sessionDuration
        CryptonetManager.shared.biometricDuration = deeplinkData?.biometricDuration
        
        self.defaultStartedType = type
        print("VERSION: - \(CryptonetManager.shared.version())")
        
        NetworkManager.shared.getSessionToken(type: type) { newToken in
            NetworkManager.shared.getPublicKey { newPublicKey in
                NetworkManager.shared.verifyDeviceHash { hashResponse in

                    CryptonetManager.shared.publicKey = deeplinkData?.publicKey ?? newPublicKey
                    
                    let finalToken = deeplinkData?.sessionToken ?? hashResponse?.sessionId ?? newToken
                    let finalKey = CryptonetManager.shared.publicKey ?? newPublicKey
                    
                    CryptonetManager.shared.sessionToken = finalToken
                    
                    if let configSessionDuration = hashResponse?.config?.sessionDuration {
                        CryptonetManager.shared.sessionDuration = String(configSessionDuration)
                    }
                    
                    if let configBiometricDuration = hashResponse?.config?.biometricDuration {
                        CryptonetManager.shared.biometricDuration = String(configBiometricDuration)
                    }
                    
                    if let configUniversalLink = hashResponse?.config?.universalLink {
                        CryptonetManager.shared.universalLink = String(configUniversalLink)
                    }
                    
                    if let configBrowser = hashResponse?.config?.browser {
                        CryptonetManager.shared.selectedBrowser = String(configBrowser)
                    }
                    
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
    }
    
    public func runVisual(on viewController: UIViewController) {
        guard let defaultStartedType = self.defaultStartedType else { return }
        
        NetworkManager.shared.checkFlowStatus { startedType in
            switch startedType ?? defaultStartedType {
            case .enroll:
                let storyboard = UIStoryboard(name: "InstructionsViewController", bundle: Bundle.module)
                let vc = storyboard.instantiateViewController(withIdentifier: "MainInstructionsViewController")
                viewController.navigationController?.pushViewController(vc, animated: true)
            case .predict:
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
