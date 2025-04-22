import UIKit
 
extension UIApplication {
    static func openIfPossible(link: String) {
        var newLink: String = link
        
        if let browser = CryptonetManager.shared.selectedBrowser {
            if browser == "chrome" {
                newLink = link.replacingOccurrences(of: "https://", with: "googlechrome://")
            } else if browser == "opera" {
                newLink = link.replacingOccurrences(of: "https://", with: "opera://")
            } else if browser == "mozilla" {
                newLink = link.replacingOccurrences(of: "https://", with: "mozilla://")
            }
        }
        
        guard let chromeURL = URL(string: newLink), let url = URL(string: link) else { return }
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(chromeURL)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if UIApplication.shared.applicationState == .active {
                    UIApplication.shared.open(url)
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    exit(0)
                }
            }
        } else {
            UIApplication.shared.open(url)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                exit(0)
            }
        }
    }
}
