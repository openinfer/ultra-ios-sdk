import UIKit
import CryptonetPackage
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
        
        testImage.image = image
        
        let result = CryptonetManager.shared.cryptonet.predict(image: image, config: PredictConfig(skipAntispoof: false, mfToken: self.mfToken))
        switch result {
        case .success(let json):
            print(json)
            self.isEnrollRunning = false
            let jsonData = Data(json.utf8)
            
            do {
                let model = try JSONDecoder().decode(NewEnrollModel.self, from: jsonData)
                self.mfToken = model.callStatus?.mfToken ?? ""
                
                if let status = model.uberOperationResult?.face?.faceValidationStatus {
                    self.handleFaceStatus(faceStatus: status)
                }
                
                if self.mfToken.isEmpty == false && self.circularProgressView?.alpha == 1.0 && self.estimateAttempts <= 100.0 {
                    self.estimateAttempts = self.estimateAttempts + 33.33
                } else if self.mfToken.isEmpty == true && model.uberOperationResult?.response?.encryptedKey == nil {
                    self.estimateAttempts = 0
                }

                if self.isFocused {
                    self.circularProgressView?.progress = self.estimateAttempts > 100.0 ? 1.0 : (self.estimateAttempts / 100)
                }
                
                if  let encryptedKey = model.uberOperationResult?.response?.encryptedKey,
                    let encryptedMessage = model.uberOperationResult?.response?.encryptedMessage,
                    let gcmAad = model.uberOperationResult?.response?.gcmAad,
                    let gcmTag = model.uberOperationResult?.response?.gcmTag,
                    let iv = model.uberOperationResult?.response?.iv {
                    DispatchQueue.main.async {
                        self.stopScan(encryptedKey: encryptedKey,
                                      encryptedMessage: encryptedMessage,
                                      gcmAad: gcmAad,
                                      gcmTag: gcmTag,
                                      iv: iv,
                                      image: image)
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
    
    func stopScan(encryptedKey: String, encryptedMessage: String, gcmAad: String, gcmTag: String, iv: String, image: UIImage) {
        self.stopSession()
        self.stopFaceAnimationTimer()
        self.stopTimer()
        self.circularProgressView?.timeToFill = 0.5
        self.circularProgressView?.progress = 1.0
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showSucccessAnimation()
            self.activityLoading.startAnimating()
            self.titleLabel.attributedText = NSAttributedString(string: "processing".localized,
                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            self.subresultLabel.attributedText = NSAttributedString(string: "100%",
                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            NetworkManager.shared.updateCollect(encryptedKey: encryptedKey, encryptedMessage: encryptedMessage, gcmAad: gcmAad, gcmTag: gcmTag, iv: iv, image: image) { [weak self] result in
                guard let self = self else { return }
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    if result == true {
                        self.showSucccessAnimation()
                        self.activityLoading.stopAnimating()
                        self.titleLabel.attributedText = NSAttributedString(string: "",
                                                                            attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
//                        self.liveIconSucceed(self.successContainer)
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            let isVerified = FlowManager.shared.current == .enroll ? false : true
                            self.navigateToVerifyingPage(isVerified: isVerified)
                        }
                    } else {
                        self.activityLoading.stopAnimating()
                        self.navigateToFinalWithFailure()
                    }
                }
            }
        }
    }
}

// MARK:- Enroll
private extension ScanViewController {
    func enroll(image: UIImage) {
        guard self.isEnrollRunning == false else { return }
        self.isEnrollRunning = true
        
        let result = CryptonetManager.shared.cryptonet.enroll(image: image, config: EnrollConfig(mfToken: self.mfToken, skipAntispoof: false))
        switch result {
        case .success(let json):
            print(json)
            self.isEnrollRunning = false
            let jsonData = Data(json.utf8)
            
            do {
                let model = try JSONDecoder().decode(NewEnrollModel.self, from: jsonData)
                self.mfToken = model.callStatus?.mfToken ?? ""
                
                if let status = model.uberOperationResult?.face?.faceValidationStatus {
                    self.handleFaceStatus(faceStatus: status)
                }
                
                if self.mfToken.isEmpty == false && self.circularProgressView?.alpha == 1.0 && self.estimateAttempts <= 100.0 {
                    self.estimateAttempts = self.estimateAttempts + 20
                } else if self.mfToken.isEmpty == true && model.uberOperationResult?.response?.encryptedKey == nil {
                    self.estimateAttempts = 0
                }
                
                if self.isFocused {
                    self.circularProgressView?.progress = self.estimateAttempts > 100.0 ? 1.0 : (self.estimateAttempts / 100)
                }
                
                if  let encryptedKey = model.uberOperationResult?.response?.encryptedKey,
                    let encryptedMessage = model.uberOperationResult?.response?.encryptedMessage,
                    let gcmAad = model.uberOperationResult?.response?.gcmAad,
                    let gcmTag = model.uberOperationResult?.response?.gcmTag,
                    let iv = model.uberOperationResult?.response?.iv {
                    self.stopScan(encryptedKey: encryptedKey,
                                  encryptedMessage: encryptedMessage,
                                  gcmAad: gcmAad,
                                  gcmTag: gcmTag,
                                  iv: iv,
                                  image: image)
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
        self.estimateAttempts = 0
        self.mfToken = ""
        self.isEnrollRunning = false
    }
}

extension ScanViewController {
    
    func handleFaceStatus(faceStatus: Int, isAntispoof: Bool = false, isHoldStill: Bool = true) {
        let isFailure = faceStatus != 0
        if isFailure {
            self.estimateAttempts = 0
            self.circularProgressView?.progress = 0.0
            self.subresultLabel.attributedText = NSAttributedString(string: "0%",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            
            if faceStatus == 10 && FlowManager.shared.current == .enroll {
                self.titleLabel.attributedText = NSAttributedString(string: "remove.glasses".localized,
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            }
        }
        
        if (FlowManager.shared.current == .signIn && faceStatus == 10) ||
            (FlowManager.shared.current == .matchFace && faceStatus == 10) {
            self.focusCamera()
        }
        
        self.isFaceScanFailed = isFailure
        
        guard self.isFocused == true || faceStatus == 0 else { return }
        
        if isAntispoof {
            switch faceStatus {
            case -100, -5, -4, -2, 1:
                self.titleLabel.attributedText = NSAttributedString(string: "increase.lighting".localized,
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case -3:
                self.titleLabel.attributedText = NSAttributedString(string: "face.into.circle".localized,
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case -1:
                self.titleLabel.attributedText = NSAttributedString(string: "looking.for.face".localized,
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
            case 5:
                self.titleLabel.attributedText = NSAttributedString(string: "Move slightly left",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 6:
                self.titleLabel.attributedText = NSAttributedString(string: "Move slightly right",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 7:
                self.titleLabel.attributedText = NSAttributedString(string: "Move your head down",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 8:
                self.titleLabel.attributedText = NSAttributedString(string: "Move your head up",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 9:
                self.titleLabel.attributedText = NSAttributedString(string: "Please hold still",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 10:
                guard FlowManager.shared.current != .signIn,
                      FlowManager.shared.current != .matchFace else { return }
                self.titleLabel.attributedText = NSAttributedString(string: "Remove glasses",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            case 11:
                self.titleLabel.attributedText = NSAttributedString(string: "Remove mask",
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
        self.isFocused = true
        self.stopSessionTimer()
        UIView.animate(withDuration: 0.6) {
            self.videoFrame.layer.cornerRadius = self.videoFrame.frame.width / 2
            self.circularProgressView?.alpha = 1.0
        }
    }
}
