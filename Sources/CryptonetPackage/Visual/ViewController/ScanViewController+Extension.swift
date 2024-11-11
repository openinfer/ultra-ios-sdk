import UIKit
import Alamofire

extension ScanViewController {
    func scan(with image: UIImage) {
        switch FlowManager.shared.current {
        case .signIn:
            self.predict(image: image)
        case .enroll:
            self.enroll(image: image)
        case .matchFace:
            self.predict(image: image)
        }
    }
}

// MARK: - Predict
extension ScanViewController {
    func predict(image: UIImage) {
        guard isEnrollRunning == false else { return }
        self.isEnrollRunning = true

        let result = CryptonetManager.shared.cryptonet!.predict(image: image, config: PredictConfig(skipAntispoof: false, mfToken: self.mfToken))
        switch result {
        case .success(let json):
            print(json)
            self.isEnrollRunning = false
            let jsonData = Data(json.utf8)
            
            do {
                let model = try JSONDecoder().decode(NewEnrollModel.self, from: jsonData)
                self.mfToken = model.callStatus?.mfToken
                
                if self.mfToken != nil && self.circularProgressView?.alpha == 1.0 {
                    self.estimateAttempts = self.estimateAttempts + 20
                    self.enrollProgress = self.enrollProgress + 0.2
                } else if self.mfToken == nil && model.callStatus?.mfToken == nil {
                    self.estimateAttempts = 0
                    self.enrollProgress = 0.0
                }
                
                if let status = model.uberOperationResult?.face?.faceValidationStatus {
                    self.handleFaceStatus(faceStatus: status)
                }

                if  let encryptedKey = model.uberOperationResult?.response?.encryptedKey,
                    let encryptedMessage = model.uberOperationResult?.response?.encryptedMessage,
                    let gcmAad = model.uberOperationResult?.response?.gcmAad,
                    let gcmTag = model.uberOperationResult?.response?.gcmTag,
                    let iv = model.uberOperationResult?.response?.iv {
                    DispatchQueue.main.async {
                        self.stopSession()
                        self.stopFaceAnimationTimer()
                        self.stopTimer()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.showSucccessAnimation()
                            self.activityLoading.startAnimating()
                            self.updatePredict(encryptedKey: encryptedKey, encryptedMessage: encryptedMessage, gcmAad: gcmAad, gcmTag: gcmTag, iv: iv)
                        }
                    }
                } else {
                    self.isEnrollRunning = false
                }
            } catch {
                self.isEnrollRunning = false
                self.enrollFailed()
                print("failure")
            }
        case .failure(_):
            print("failure")
            self.isEnrollRunning = false
        }
    }
}

// MARK:- Enroll
private extension ScanViewController {
    func enroll(image: UIImage) {
        guard self.isEnrollRunning == false else { return }
        self.isEnrollRunning = true
        
        let result = CryptonetManager.shared.cryptonet!.enroll(image: image, config: EnrollConfig(mfToken: self.mfToken, skipAntispoof: false))
        switch result {
        case .success(let json):
            print(json)
            self.isEnrollRunning = false
            let jsonData = Data(json.utf8)
            
            do {
                let model = try JSONDecoder().decode(NewEnrollModel.self, from: jsonData)
                self.mfToken = model.callStatus?.mfToken
                
                if self.mfToken != nil && self.circularProgressView?.alpha == 1.0 {
                    self.estimateAttempts = self.estimateAttempts + 20
                    self.enrollProgress = self.enrollProgress + 0.2
                } else if self.mfToken == nil && model.callStatus?.mfToken == nil {
                    self.estimateAttempts = 0
                    self.enrollProgress = 0.0
                }
                
                if let status = model.uberOperationResult?.face?.faceValidationStatus {
                    self.handleFaceStatus(faceStatus: status)
                }

                if  let encryptedKey = model.uberOperationResult?.response?.encryptedKey,
                    let encryptedMessage = model.uberOperationResult?.response?.encryptedMessage,
                    let gcmAad = model.uberOperationResult?.response?.gcmAad,
                    let gcmTag = model.uberOperationResult?.response?.gcmTag,
                    let iv = model.uberOperationResult?.response?.iv {
                    DispatchQueue.main.async {
                        self.stopSession()
                        self.stopFaceAnimationTimer()
                        self.stopTimer()
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                            self.showSucccessAnimation()
                            self.activityLoading.startAnimating()
                            self.updateEnroll(encryptedKey: encryptedKey, encryptedMessage: encryptedMessage, gcmAad: gcmAad, gcmTag: gcmTag, iv: iv)
                        }
                    }
                } else {
                    self.isEnrollRunning = false
                }
            } catch {
                self.isEnrollRunning = false
                self.enrollFailed()
                print("failure")
            }
        case .failure(_):
            self.isEnrollRunning = false
            self.enrollFailed()
            print("failure")
        }
    }
    
    private func enrollFailed() {
        self.enrollProgress = 0.0
        self.estimateAttempts = 0
        self.mfToken = nil
        self.isEnrollRunning = false
    }
}

extension ScanViewController {
    
    func handleFaceStatus(faceStatus: Int, isAntispoof: Bool = false, isHoldStill: Bool = true) {
        let isFailure = faceStatus != 0 && faceStatus != 10
        if isFailure {
            self.estimateAttempts = 0
            self.subresultLabel.attributedText = NSAttributedString(string: "0%",
                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
        }

        self.isFaceScanFailed = isFailure
        
        guard self.isFocused == true || faceStatus == 0 else { return }

        if isAntispoof {
            switch faceStatus {
            case -100, -5, -4, -2, 1:
                self.titleLabel.attributedText = NSAttributedString(string: "Too dim - increase lighting",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case -3:
                self.titleLabel.attributedText = NSAttributedString(string: "Move face into circle",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case -1:
                self.titleLabel.attributedText = NSAttributedString(string: "Looking for face",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            default: break
            }
            
        } else {
            switch faceStatus {
            case -100, -1:
                self.titleLabel.attributedText = NSAttributedString(string: "",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 0:
                self.focusCamera()
                if isHoldStill {
                    self.titleLabel.attributedText = NSAttributedString(string: "Processing hold still",
                                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
                }
            case 1, 2, 3:
                self.titleLabel.attributedText = NSAttributedString(string: "Please move back",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 4:
                self.titleLabel.attributedText = NSAttributedString(string: "Please move closer",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 5, 6, 7, 8:
                self.titleLabel.attributedText = NSAttributedString(string: "Move face into circle",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 9:
                self.titleLabel.attributedText = NSAttributedString(string: "Please hold still",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 10:
                self.titleLabel.attributedText = NSAttributedString(string: "Remove glasses",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 11:
                self.titleLabel.attributedText = NSAttributedString(string: "",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 12, 13:
                self.titleLabel.attributedText = NSAttributedString(string: "Please look at camera",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 14:
                self.titleLabel.attributedText = NSAttributedString(string: "Raise phone level to face",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 15:
                self.titleLabel.attributedText = NSAttributedString(string: "Lower phone level to face",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 16:
                self.titleLabel.attributedText = NSAttributedString(string: "Too dim - increase lighting",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 17:
                self.titleLabel.attributedText = NSAttributedString(string: "Too bright - lower lighting",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 18:
                self.titleLabel.attributedText = NSAttributedString(string: "Please hold still",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 19:
                self.titleLabel.attributedText = NSAttributedString(string: "",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 20:
                self.titleLabel.attributedText = NSAttributedString(string: "Please hold still",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 21:
                self.titleLabel.attributedText = NSAttributedString(string: "Please close mouth",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 22, 23:
                self.titleLabel.attributedText = NSAttributedString(string: "Please straighten head",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            default:
                self.titleLabel.attributedText = NSAttributedString(string: "",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            }
        }
    }
    
    func focusCamera() {
        UIView.animate(withDuration: 0.6) {
            self.videoFrame.layer.cornerRadius = self.videoFrame.frame.width / 2
            self.circularProgressView?.alpha = 1.0
        } completion: { _ in
            self.isFocused = true
        }
    }
}

extension ScanViewController {
    func updateEnroll(encryptedKey: String, encryptedMessage: String, gcmAad: String, gcmTag: String, iv: String) {
        self.titleLabel.attributedText = NSAttributedString(string: "Processing...",
                                                            attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
        guard let token = CryptonetManager.shared.sessionToken,
              let url = URL(string: "https://api-orchestration-privateid.uberverify.com/v2/verification-session/\(token)/enroll") else { return }
        
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.showSucccessAnimation()
                        self.activityLoading.stopAnimating()
                        self.titleLabel.attributedText = NSAttributedString(string: "Success",
                                                                            attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
                        self.liveIconSucceed(self.successContainer)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.navigateToVerifyingPage(isVerified: false)
                        }
                    }
                case .failure:
                    self.activityLoading.stopAnimating()
                    self.navigateToFinalWithFailure()
                }
            }
    }
    
    func updatePredict(encryptedKey: String, encryptedMessage: String, gcmAad: String, gcmTag: String, iv: String) {
        self.titleLabel.attributedText = NSAttributedString(string: "Processing...",
                                                            attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
        guard let token = CryptonetManager.shared.sessionToken,
              let url = URL(string: "https://api-orchestration-privateid.uberverify.com/v2/verification-session/\(token)/verify") else { return }
        
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
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                        self.activityLoading.stopAnimating()
                        self.titleLabel.attributedText = NSAttributedString(string: "Success",
                                                                            attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
                        self.liveIconSucceed(self.successContainer)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            self.navigateToVerifyingPage(isVerified: true)
                        }
                    }
                case .failure:
                    self.activityLoading.stopAnimating()
                    self.navigateToFinalWithFailure()
                }
            }
    }
}
