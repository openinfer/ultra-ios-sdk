import UIKit
import Alamofire
import ProgressHUD

final class NetworkManager {
    
    enum SessionFlow: String {
        case enroll = "ENROLL"
        case predict = "VERIFY"
    }
    
    static let shared = NetworkManager()
    
    var baseURL = "https://api-orchestration-privateid.uberverify.com/"
    var redirectURL = "https://privateid.uberverify.com"
    
    private init() { }
    
    func getSessionToken(with uuid: String = UUID().uuidString, type: SessionFlow = .predict, token: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(baseURL)v2/verification-session") else {
            token(nil)
            return
        }
        
        let params: [String : Any] = [
            "type" : type.rawValue,
            "redirectURL" : redirectURL,
            "deviceInfo" : [:],
            "callback" : [
                "url" : redirectURL,
                "headers" : [:]
            ],
            "uuid": uuid
        ]
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "skip-auth",
            "x-api-key": "0000000000000000test"
        ]
        
        AF.request(url, method: .post, parameters: params, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseDecodable(of: ResponseModel.self) { response in
                switch response.result {
                case .success(let response):
                    token(response.sessionId)
                case .failure(let error):
                    print("Failed: \(error.localizedDescription)")
                    ProgressHUD.failed("Internal server error")
                    token(nil)
                }
            }
    }
    
    func getPublicKey(publicKey: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(baseURL)public-key") else {
            publicKey(nil)
            return
        }
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "skip-auth",
            "x-api-key": "0000000000000000test"
        ]
        
        AF.request(url, method: .get, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseDecodable(of: ResponseModel.self) { response in
                switch response.result {
                case .success(let response):
                    publicKey(response.publicKey)
                case .failure(let error):
                    print("Failed: \(error.localizedDescription)")
                    ProgressHUD.failed("Internal server error")
                    publicKey(nil)
                }
            }
    }
    
    
    func checkFlowStatus(finished: @escaping (Bool) -> Void) {
        guard let sessionToken = CryptonetManager.shared.sessionToken,
              let url = URL(string: "\(baseURL)v2/verification-session/\(sessionToken)") else {
            ProgressHUD.failed("Internal server error")
            finished(false)
            return
        }
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "Authorization": "skip-auth",
            "x-api-key": "0000000000000000test"
        ]
        
        AF.request(url, method: .get, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseDecodable(of: ResponseModel.self) { [weak self] response in
                guard let self = self else { return }
                switch response.result {
                case .success(let response):
                    if response.type == "ENROLL" {
                        FlowManager.shared.current = .enroll
                    } else {
                        FlowManager.shared.current = .matchFace
                    }
                    
                    let link = response.redirectURL ?? self.redirectURL
                    if link.hasPrefix("https://") {
                        CryptonetManager.shared.redirectURL = link
                    } else {
                        CryptonetManager.shared.redirectURL = "https://" + link
                    }
                    
                    finished(true)
                case .failure(let error):
                    print("Failed: \(error.localizedDescription)")
                    ProgressHUD.failed("Internal server error")
                    finished(false)
                }
            }
    }
}
