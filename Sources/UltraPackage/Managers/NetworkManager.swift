import UIKit
import Alamofire
import ProgressHUD

public final class NetworkManager {
    
    public enum SessionFlow: String {
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
    
    
    func checkFlowStatus(finished: @escaping (NetworkManager.SessionFlow?) -> Void) {
        guard let sessionToken = CryptonetManager.shared.sessionToken,
              let url = URL(string: "\(baseURL)v2/verification-session/\(sessionToken)") else {
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
                var flowType: NetworkManager.SessionFlow? = nil
                switch response.result {
                case .success(let response):
                    if response.type == "ENROLL" {
                        FlowManager.shared.current = .enroll
                        flowType = .enroll
                    } else {
                        FlowManager.shared.current = .matchFace
                        flowType = .predict
                    }
                    
                    let link = response.redirectURL ?? self.redirectURL
                    if link.hasPrefix("https://") {
                        CryptonetManager.shared.redirectURL = link
                    } else {
                        CryptonetManager.shared.redirectURL = "https://" + link
                    }
                    
                    finished(flowType)
                case .failure(let error):
                    print("Failed: \(error.localizedDescription)")
                    ProgressHUD.failed("Internal server error")
                    finished(nil)
                }
            }
    }
    
    func fetchSessionDetails(responseModel: @escaping (SessionDetailsModel?) -> Void) {
        guard let token = CryptonetManager.shared.sessionToken,
              let url = URL(string: "\(baseURL)v2/verification-session/\(token)/webhook-payload") else {
            responseModel(nil)
            return
        }
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        AF.request(url, method: .get, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseDecodable(of: SessionDetailsModel.self) { response in
                switch response.result {
                case .success(let model):
                    responseModel(model)
                case .failure:
                    responseModel(nil)
                }
            }
    }
    
    func sendFeedback(feedback: String, finished: @escaping (Bool) -> Void) {
        guard let token = CryptonetManager.shared.sessionToken,
              let url = URL(string: "\(baseURL)v2/verification-session/\(token)/feedback") else {
            finished(false)
            return
        }
        
        let parameters: [String : Any] = [
            "feedback": feedback
        ]
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseDecodable(of: ResponseModel.self) { response in
                switch response.result {
                case .success:
                    finished(true)
                case .failure:
                    finished(false)
                }
            }
    }
    
    func updateImage(image: UIImage) {
        guard let token = CryptonetManager.shared.sessionToken,
              let url = URL(string: "\(baseURL)v2/verification-session/\(token)/img") else { return }
        
        guard let imageData = image.jpegData(compressionQuality: 0.3) else {
            print("Failed to convert image to data")
            return
        }
        
        // Headers (optional)
        let headers: HTTPHeaders = [
            "Content-Type": "multipart/form-data",
            "x-api-key": "0000000000000000test"
        ]
        
        AF.upload(
            multipartFormData: { multipartFormData in
                multipartFormData.append(imageData, withName: "portrait", fileName: UUID().uuidString, mimeType: "image/jpeg")
            },
            to: url,
            headers: headers
        ).response { response in
            switch response.result {
            case .success(let data):
                if let jsonData = data {
                    print("Success:", String(data: jsonData, encoding: .utf8) ?? "No readable response")
                }
            case .failure(let error):
                print("Error uploading image:", error.localizedDescription)
            }
        }
    }
    
    func updateCollect(encryptedKey: String, encryptedMessage: String, gcmAad: String, gcmTag: String, iv: String, image: UIImage, finished: @escaping (Bool) -> Void) {
        self.updateImage(image: image)
        
        guard let token = CryptonetManager.shared.sessionToken,
              let url = URL(string: "\(baseURL)v2/verification-session/\(token)/collect") else {
            finished(false)
            return
        }
        
        let parameters: [String : Any] = [
            "encryptedKey": encryptedKey,
            "encryptedMessage": encryptedMessage,
            "gcmAad": gcmAad,
            "gcmTag": gcmTag,
            "iv": iv
        ]
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseDecodable(of: ResponseModel.self) { response in
                switch response.result {
                case .success:
                    finished(true)
                case .failure:
                    finished(false)
                }
            }
    }
    
    
    func updateEnroll(encryptedKey: String, encryptedMessage: String, gcmAad: String, gcmTag: String, iv: String, finished: @escaping (Bool) -> Void) {
        guard let token = CryptonetManager.shared.sessionToken,
              let url = URL(string: "\(baseURL)v2/verification-session/\(token)/enroll") else { return }
        
        let parameters: [String : Any] = [
            "encryptedKey": encryptedKey,
            "encryptedMessage": encryptedMessage,
            "gcmAad": gcmAad,
            "gcmTag": gcmTag,
            "iv": iv
        ]
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseDecodable(of: ResponseModel.self) { response in
                switch response.result {
                case .success:
                    finished(true)
                case .failure:
                    finished(false)
                }
            }
    }
    
    func updatePredict(encryptedKey: String, encryptedMessage: String, gcmAad: String, gcmTag: String, iv: String, finished: @escaping (Bool) -> Void) {
        guard let token = CryptonetManager.shared.sessionToken,
              let url = URL(string: "\(baseURL)v2/verification-session/\(token)/verify") else { return }
        
        let parameters: [String : Any] = [
            "encryptedKey": encryptedKey,
            "encryptedMessage": encryptedMessage,
            "gcmAad": gcmAad,
            "gcmTag": gcmTag,
            "iv": iv
        ]
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        AF.request(url, method: .post, parameters: parameters, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseDecodable(of: ResponseModel.self) { response in
                switch response.result {
                case .success:
                    finished(true)
                case .failure:
                    finished(false)
                }
            }
    }
    
    func verifyDeviceHash(completion: @escaping (ResponseModel?) -> Void) {
        let deviceHashProvider = DeviceHashProvider()
        deviceHashProvider.getDeviceHash { deviceHash in
            guard let url = URL(string: "\(self.baseURL)v2/verification-session/hash/\(deviceHash)") else {
                completion(nil)
                return
            }
            
            let headers: HTTPHeaders = [
                "Content-Type": "application/json",
                "Authorization": "skip-auth",
                "x-api-key": "0000000000000000test"
            ]
            
            AF.request(url, method: .get, headers: headers)
                .validate()
                .responseDecodable(of: ResponseModel.self) { response in
                    switch response.result {
                    case .success(let model):
                        completion(model)
                    case .failure(let error):
                        print("Failed: \(error.localizedDescription)")
                        ProgressHUD.failed("Internal server error")
                        completion(nil)
                    }
                }
        }
    }
}
