import Foundation
import UIKit
import CryptoKit
import WebKit

class DeviceHashProvider {
    private let systemName = "iOS"
    private let unknownSystemName = "Unknown"
    private let messageDigestAlg = "SHA256"
    
    /**
     * Generates a unique SHA-256 hash representing the current device's key characteristics.
     *
     * The hash is computed from the following components:
     * - System name (iOS)
     * - iOS version
     * - Screen resolution in points (width x height)
     * - Public IP address (if retrievable)
     */
    func getDeviceHash(completion: @escaping (String) -> Void) {
        let screenSize = UIScreen.main.bounds.size
        let screenWidth = Int(screenSize.width)
        let screenHeight = Int(screenSize.height)
        
        getPublicIpAddress { ipAddress in
            let components = [
                self.systemName,
                UIDevice.current.systemVersion,
                "\(screenWidth)x\(screenHeight)",
                ipAddress ?? "unknown"
            ]
            
            let hashString = components.joined(separator: "-")
            let hash = self.hashSHA256(str: hashString)

            completion(hash)
        }
    }
    
    /**
     * Retrieves the device's public IP address by making a network request.
     */
    private func getPublicIpAddress(completion: @escaping (String?) -> Void) {
        let ipFetcher = IPFetcherViewController()
        ipFetcher.getPublicIpAddressUsingWebView { ip in
            if let ip = ip {
                completion(ip)
            } else {
                completion(nil)
            }
        }
    }
    
    /**
     * Computes the SHA-256 hash of the given input string.
     */
    func hashSHA256(str: String) -> String {
        print("Input string: [\(str)]")
        print("Input bytes:", Array(str.utf8))
        print("Character count:", str.count)

        let cleanedInput = str.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let inputData = cleanedInput.data(using: .utf8) else {
            return ""
        }
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

class IPFetcherViewController: UIViewController, WKNavigationDelegate {
    private var webView: WKWebView!
    private var completion: ((String?) -> Void)?
    
    func getPublicIpAddressUsingWebView(completion: @escaping (String?) -> Void) {
        self.completion = completion
        
        let webConfiguration = WKWebViewConfiguration()
        webConfiguration.websiteDataStore = .nonPersistent() // optional: no cookies
        
        webView = WKWebView(frame: .zero, configuration: webConfiguration)
        webView.navigationDelegate = self
        view.addSubview(webView) // you can keep it hidden if you want
        
        if let url = URL(string: "https://api.ipify.org?format=json") {
            let request = URLRequest(url: url)
            webView.load(request)
        } else {
            completion(nil)
        }
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webView.evaluateJavaScript("document.body.innerText") { [weak self] (result, error) in
            guard let self = self else { return }
            if let text = result as? String {
                if let data = text.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let ip = json["ip"] as? String {
                    self.completion?(ip)
                } else {
                    self.completion?(nil)
                }
            } else {
                self.completion?(nil)
            }
        }
    }
}
