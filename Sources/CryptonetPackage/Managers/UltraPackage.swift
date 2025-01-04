import UIKit

enum CryptonetError: Error {
    case noJSON
    case failed
}

public class UltraPackage {
    
    private var sessionPointer: UnsafeMutableRawPointer?
    
    public init() {}
    
    public func start(path: NSString, token: NSString, publicKey: NSString, baseURL: NSString, securityModel: SecurityModel) -> Bool {
        
        let settings = """
        {
          "collections": {
            "default": {
              "named_urls": {
                "base_url": "\(baseURL)" } } },
          "public_key": "\(publicKey)",
          "session_token": "\(token)"
        }
        """
        CryptonetManager.shared.sessionToken = String(token)
        
        CryptonetManager.shared.initializeLib(path: path)
        let result = CryptonetManager.shared.initializeSession(settings: NSString(string: settings))
        let securityCheck = self.checkSecurityConditions(securityModel: securityModel)
        return result && securityCheck
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
