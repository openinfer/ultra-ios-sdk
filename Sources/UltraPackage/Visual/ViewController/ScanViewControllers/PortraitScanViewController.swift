import UIKit
import AVFoundation
import CoreMedia
import Toaster
import ProgressHUD
import CryptonetPackage
import Alamofire

final class PortraitScanViewController: BaseViewController {
    
    @IBOutlet weak var videoFrame: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var activityLoading: UIActivityIndicatorView!
    @IBOutlet weak var footerContainer: UIView!
    @IBOutlet weak var faceIdImage: UIImageView!
    @IBOutlet weak var circularProgressView: CircularProgressView!
    
    private let footer: FooterView = .fromNib()
    
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    private var timer: Timer?
    private var timeInterval: TimeInterval = 0.3
    
    var sessionTimer: Timer?
    var sessionTimeInterval: TimeInterval = 1.0
    var sessionCountdown: Int = 45
    
    private var tempImage: UIImage?
    private var isCameraRunning = false
    
    private var cameraStartTime: Date?
    private var cameraLunchTime: String = ""
    
    private var mfToken: String = ""
    private var isImageTaking: Bool = false
    private var isFocused: Bool = false
    private var isFaceIdRunning: Bool = false
    private var lastOrientation: UIDeviceOrientation?
    
    private var faceIDStartTime: Date?
    private var faceIDExecutionTime: TimeInterval = 0
    private var faceIDDurationTime: Double {
        var defaultTime = 1.5
        if let faceidDuration = CryptonetManager.shared.deeplinkData?.faceidDuration,
           let customTime = Double(faceidDuration) {
            defaultTime = customTime
        }
        
        return defaultTime
    }
    
    private var sessionStartTime: Date?
    private var sessionExecutionTime: TimeInterval = 0
    private var sessionDurationTime: Double {
        var defaultTime = 3.5
        if let sessionDuration = CryptonetManager.shared.deeplinkData?.sessionDuration,
           let customTime = Double(sessionDuration) {
            defaultTime = customTime
        }
        
        return defaultTime
    }
    
    var estimateAttempts: Float = 0.0 {
        willSet {
            self.changeResultLabel(attributedText: NSAttributedString(string: "\(Int(newValue))%" + " " + "recognised".localized,
                                                                      attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
        }
    }
    
    // MARK: Life circule
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(checkOrientationUI), name: UIDevice.orientationDidChangeNotification, object: nil)
        self.setupUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CryptonetManager.shared.startDeviceInfoCollect(with: self.cameraLunchTime)
        if isCameraRunning == false {
            isCameraRunning = true
            setupCamera()
            setupTimer()
            startSession()
            circularProgressView.redraw()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
        stopSession()
        stopSessionTimer()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        footer.frame = footerContainer.bounds
        previewLayer?.frame = videoFrame.layer.bounds
    }
    
    // MARK:- Actions
    
    @objc func checkOrientationUI() {
        DispatchQueue.main.async {
            if self.isValidOrientation() {
                if self.session.isRunning == false {
                    self.circularProgressView.redraw()
                    DispatchQueue.global(qos: .userInitiated).async {
                        self.session.startRunning()
                    }
                }
            } else {
                self.session.stopRunning()
            }
        }
    }
    
    @IBAction func backTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func backToRoot() {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func captureVideoFrame() {
        DispatchQueue.main.async {
            if let image = self.tempImage, self.session.isRunning == true  {
                self.scan(with: image)
            }
        }
    }
    
    @objc func sessionTimerAction() {
        sessionCountdown -= 1
        ToastCenter.default.currentToast?.cancel()
        
        if sessionCountdown <= 20 && sessionCountdown > 10 {
            Toast(text: String(format: "session_timer_title".localized, "\(sessionCountdown)"), duration: Delay.short).show()
        } else if sessionCountdown <= 10 && sessionCountdown > 5 {
            ToastView.appearance().backgroundColor = .yellow
            ToastView.appearance().textColor = .black
            Toast(text: String.init(format: "session_timer_title".localized, "\(sessionCountdown)"), duration: Delay.short).show()
        } else if sessionCountdown <= 5 && sessionCountdown > 0 {
            ToastView.appearance().backgroundColor = .red
            ToastView.appearance().textColor = .white
            Toast(text: String.init(format: "session_timer_title".localized, "\(sessionCountdown)"), duration: Delay.short).show()
        } else if sessionCountdown <= 0 {
            ToastView.appearance().backgroundColor = .red
            ToastView.appearance().textColor = .white
            Toast(text: String("session_timer_error".localized), duration: Delay.short).show()
            stopSessionTimer()
            reset()
        }
    }
    
    func updateCounter(currentValue: Int, toValue: Double) {
        if currentValue <= Int(toValue * 100) {
            self.changeResultLabel(attributedText: NSAttributedString(string: "\(currentValue)%" + " " + "recognised".localized,
                                                                      attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            let dispatchTime: DispatchTime = DispatchTime.now() + Double(Int64(0.01 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                self.updateCounter(currentValue: currentValue + 1, toValue: toValue)
            })
        }
    }
}

// MARK:- Private
private extension PortraitScanViewController {
    
    func setupUI() {
        changeTitle(attributedText: NSAttributedString(string: "center.your.head".localized,
                                                       attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
        footer.delegate = self
        footerContainer.addSubview(footer)
        
        ToastView.appearance().bottomOffsetPortrait = self.view.frame.height - 150.0
        ToastView.appearance().font = UIFont.systemFont(ofSize: 16)
        
        setupProgress()
    }
    
    func setupProgress() {
        circularProgressView.rounded = false
        circularProgressView.progressColor = .systemGreen
        circularProgressView.trackColor = .white
        circularProgressView.alpha = 0.0
        circularProgressView.redraw()
    }
    
    func focusCamera() {
        self.isFocused = true
        self.stopSessionTimer()
        UIView.animate(withDuration: 0.6) {
            self.videoFrame.layer.cornerRadius = self.videoFrame.frame.width / 2
            self.circularProgressView.alpha = 1.0
        }
    }
    
    func setupTimer() {
        timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(captureVideoFrame), userInfo: nil, repeats: true)
    }
    
    func startSessionTimer() {
        stopSessionTimer()
        sessionTimer = Timer.scheduledTimer(timeInterval: sessionTimeInterval,
                                            target: self,
                                            selector: #selector(sessionTimerAction),
                                            userInfo: nil, repeats: true)
    }
    
    func stopSessionTimer() {
        sessionTimer?.invalidate()
        sessionTimer = nil
    }
    
    func stopTimer() {
        if timer?.isValid == true {
            timer?.invalidate()
            timer = nil
        }
    }
    
    func startSession() {
        if !session.isRunning {
            cameraStartTime = Date()
            let isValidOrientation = self.isValidOrientation()
            DispatchQueue.global(qos: .userInitiated).async {
                if isValidOrientation && self.session.isRunning == false {
                    self.session.startRunning()
                }
            }
        }
    }
    
    func stopSession() {
        if session.isRunning {
            isCameraRunning = false
            self.stopTimer()
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.stopRunning()
            }
        }
    }
    
    func finishFlow(isSuccess: Bool) {
        stopTimer()
        stopSession()
        //
    }
    
    func showSucccessAnimation() {
        UIView.animate(
            withDuration: 0.5,
            animations: {
                self.circularProgressView.alpha = 0.0
                self.videoFrame.transform = CGAffineTransform(scaleX: 0.0001, y: 0.0001)
            })
    }
    
    func changeTitle(attributedText: NSAttributedString) {
        titleLabel.attributedText = attributedText
    }
    
    func changeResultLabel(attributedText: NSAttributedString) {
        resultLabel.attributedText = attributedText
    }
        
    func setupCamera() {
        session.sessionPreset = .photo
        
        
        let possition: AVCaptureDevice.Position = .front
        
        let cameraType: AVCaptureDevice.DeviceType = .builtInWideAngleCamera
        guard let captureDevice = AVCaptureDevice.default(cameraType, for: .video, position: possition) else { return }
        
        do {
            let input = try AVCaptureDeviceInput(device: captureDevice)
            session.addInput(input)
            
            previewLayer = AVCaptureVideoPreviewLayer(session: session)
            previewLayer?.videoGravity = .resizeAspectFill
            previewLayer?.contentsGravity = .resizeAspectFill
            
            previewLayer?.frame = videoFrame.layer.bounds
            videoFrame.layer.addSublayer(previewLayer!)
            
            let output = AVCaptureVideoDataOutput()
            output.setSampleBufferDelegate(self, queue: DispatchQueue(label: "videoQueue"))
            session.addOutput(output)
            
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func isValidOrientation() -> Bool {
        var result = false
        switch UIDevice.current.orientation {
        case .portrait:
            result = true
        case .portraitUpsideDown, .landscapeRight, .landscapeLeft, .unknown:
            result = false
        case .faceUp, .faceDown:
            if self.lastOrientation == .portrait {
                return true
            } else {
                return false
            }
        @unknown default:
            result = false
        }
        
        self.lastOrientation = UIDevice.current.orientation
        return result
    }
}

// MARK:- AVCaptureVideoDataOutputSampleBufferDelegate
extension PortraitScanViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let startTime = cameraStartTime {
            let elapsedTime = Date().timeIntervalSince(startTime)
            print("Camera launch time: \(elapsedTime) seconds")
            self.cameraLunchTime = "\(elapsedTime) seconds"
            cameraStartTime = nil // Reset to avoid multiple prints
        }
        DispatchQueue.global(qos: .userInitiated).async {
            connection.videoOrientation = .portrait
            let imageBuffer: CVPixelBuffer = sampleBuffer.imageBuffer!
            let ciimage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
            let image: UIImage = UIImage.convert(cmage: ciimage)
            print("Image: \(image.size)")
            self.tempImage = UIImage.cropImageToSquare(image: image)
        }
    }
}

// MARK: - Navigation

extension PortraitScanViewController: FooterViewDelegate {
    func feedbackTapped() {
        let storyboard = UIStoryboard(name: "FeedbackViewController", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "FeedbackViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func navigateToFinalWithFailure() {
        let storyboard = UIStoryboard(name: "VerifyingViewController", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "MainVerifyingViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    func navigateToVerifyingPage(isVerified: Bool) {
        let storyboard = UIStoryboard(name: "VerifyingViewController", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "MainVerifyingViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: Scan Work

extension PortraitScanViewController {
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
extension PortraitScanViewController {
    func predict(image: UIImage) {
        guard isImageTaking == false && isFaceIdRunning == false else { return }
        self.isImageTaking = true
        
        let result = CryptonetManager.shared.cryptonet.predict(image: image, config: PredictConfig(skipAntispoof: false, mfToken: self.mfToken))
        switch result {
        case .success(let json):
            print(json)
            self.isImageTaking = false
            let jsonData = Data(json.utf8)
            
            do {
                let model = try JSONDecoder().decode(NewEnrollModel.self, from: jsonData)
                let token = model.callStatus?.mfToken ?? ""
                if self.mfToken.isEmpty == true &&
                   token.isEmpty == false {
                    self.mfToken = token
                    self.startScanSession()
                } else {
                    self.mfToken = token
                }

                if let status = model.uberOperationResult?.face?.faceValidationStatus {
                    self.handleFaceStatus(faceStatus: status, image: image)
                }
                
                if self.mfToken.isEmpty == false && self.estimateAttempts <= 100.0 {
                    self.estimateAttempts = self.estimateAttempts + 33.33
                } else if self.mfToken.isEmpty == true && model.uberOperationResult?.response?.encryptedKey == nil {
                    self.estimateAttempts = 0
                }
                
                if self.isFocused {
                    self.circularProgressView.progress = self.estimateAttempts > 100.0 ? 1.0 : (self.estimateAttempts / 100)
                }
                
                if  let encryptedKey = model.uberOperationResult?.response?.encryptedKey,
                    let encryptedMessage = model.uberOperationResult?.response?.encryptedMessage,
                    let gcmAad = model.uberOperationResult?.response?.gcmAad,
                    let gcmTag = model.uberOperationResult?.response?.gcmTag,
                    let iv = model.uberOperationResult?.response?.iv {
                    self.finishedScanSession()
                    DispatchQueue.main.async {
                        self.stopScan(encryptedKey: encryptedKey,
                                      encryptedMessage: encryptedMessage,
                                      gcmAad: gcmAad,
                                      gcmTag: gcmTag,
                                      iv: iv,
                                      image: image)
                    }
                } else {
                    self.isImageTaking = false
                }
            } catch {
                self.isImageTaking = false
                self.enrollFailed()
                print("failure")
            }
        case .failure(_):
            self.enrollFailed()
            print("failure")
            self.isImageTaking = false
        }
    }
    
    func stopScan(encryptedKey: String, encryptedMessage: String, gcmAad: String, gcmTag: String, iv: String, image: UIImage) {
        self.stopSession()
        self.stopTimer()
        self.circularProgressView.timeToFill = 0.5
        self.circularProgressView.progress = 1.0
        self.activityLoading.startAnimating()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            self.showSucccessAnimation()
            self.changeTitle(attributedText: NSAttributedString(string: "processing".localized,
                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            self.changeResultLabel(attributedText: NSAttributedString(string: "100%" + " " + "recognised".localized,
                                                                      attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            self.updateCollectWithData(encryptedKey: encryptedKey,
                                       encryptedMessage: encryptedMessage,
                                       gcmAad: gcmAad,
                                       gcmTag: gcmTag,
                                       iv: iv,
                                       image: image)
        }
    }
    
    private func updateCollectWithData(encryptedKey: String, encryptedMessage: String, gcmAad: String, gcmTag: String, iv: String, image: UIImage) {
        guard let info = CryptonetManager.shared.getDeviceInfo() else {
            print("Failure during getting getDeviceInfo")
            return
        }
        
        let result = CryptonetManager.shared.cryptonet.encryptPayload(json: NSString(string: info))
        switch result {
        case .success(let json):
            let jsonData = Data(json.utf8)
            do {
                let model = try JSONDecoder().decode(CollectModel.self, from: jsonData)
                
                if  let collectEncryptedKey = model.uberOperationResult?.request?.encryptedKey,
                    let collectEncryptedMessage = model.uberOperationResult?.request?.encryptedMessage,
                    let collectGcmAad = model.uberOperationResult?.request?.gcmAad,
                    let collectGcmTag = model.uberOperationResult?.request?.gcmTag,
                    let collectIv = model.uberOperationResult?.request?.iv {
                    
                    NetworkManager.shared.updateCollect(encryptedKey: collectEncryptedKey,
                                                        encryptedMessage: collectEncryptedMessage,
                                                        gcmAad: collectGcmAad,
                                                        gcmTag: collectGcmTag,
                                                        iv: collectIv,
                                                        image: image) { [weak self] result in
                        if result == true {
                            self?.updateFinalData(encryptedKey: encryptedKey,
                                                  encryptedMessage: encryptedMessage,
                                                  gcmAad: gcmAad,
                                                  gcmTag: gcmTag,
                                                  iv: iv)
                        } else {
                            print("failure")
                        }
                    }
                } else {
                    print("failure")
                }
            } catch {
                print("failure")
            }
        case .failure(_):
            print("failure")
        }
    }
    
    private func updateFinalData(encryptedKey: String, encryptedMessage: String, gcmAad: String, gcmTag: String, iv: String) {
        switch FlowManager.shared.current {
        case .signIn, .matchFace:
            NetworkManager.shared.updatePredict(encryptedKey: encryptedKey,
                                                encryptedMessage: encryptedMessage,
                                                gcmAad: gcmAad,
                                                gcmTag: gcmTag,
                                                iv: iv, finished: { [weak self] finished in
                self?.updateFinalUI(isFinished: finished)
                
            })
        case .enroll:
            NetworkManager.shared.updateEnroll(encryptedKey: encryptedKey,
                                               encryptedMessage: encryptedMessage,
                                               gcmAad: gcmAad,
                                               gcmTag: gcmTag,
                                               iv: iv,
                                               finished: { [weak self] finished in
                self?.updateFinalUI(isFinished: finished)
            })
        }
    }
    
    private func updateFinalUI(isFinished: Bool) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            if isFinished == true {
                self.showSucccessAnimation()
                self.changeTitle(attributedText: NSAttributedString(string: "",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    let isVerified = FlowManager.shared.current == .enroll ? false : true
                    self.navigateToVerifyingPage(isVerified: isVerified)
                }
            } else {
                self.navigateToFinalWithFailure()
            }
        }
    }
}

// MARK:- Enroll
private extension PortraitScanViewController {
    func enroll(image: UIImage) {
        guard self.isImageTaking == false && isFaceIdRunning == false else { return }
        self.isImageTaking = true
        
        let result = CryptonetManager.shared.cryptonet.enroll(image: image, config: EnrollConfig(mfToken: self.mfToken, skipAntispoof: false))
        switch result {
        case .success(let json):
            print(json)
            self.isImageTaking = false
            let jsonData = Data(json.utf8)
            
            do {
                let model = try JSONDecoder().decode(NewEnrollModel.self, from: jsonData)
                let token = model.callStatus?.mfToken ?? ""
                if self.mfToken.isEmpty == true &&
                   token.isEmpty == false {
                    self.mfToken = token
                    self.showFaceID()
                } else {
                    self.mfToken = token
                }
                
                self.mfToken = token
                
                if let status = model.uberOperationResult?.face?.faceValidationStatus {
                    self.handleFaceStatus(faceStatus: status, image: image)
                }
                
                if self.mfToken.isEmpty == false && self.estimateAttempts <= 100.0 {
                    self.estimateAttempts = self.estimateAttempts + 20
                } else if self.mfToken.isEmpty == true && model.uberOperationResult?.response?.encryptedKey == nil {
                    self.estimateAttempts = 0
                }
                
                if self.isFocused {
                    self.circularProgressView.progress = self.estimateAttempts > 100.0 ? 1.0 : (self.estimateAttempts / 100)
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
                    self.isImageTaking = false
                }
            } catch {
                self.isImageTaking = false
                self.enrollFailed()
                print("failure")
            }
        case .failure(_):
            self.isImageTaking = false
            self.enrollFailed()
            print("failure")
        }
    }
    
    private func enrollFailed() {
        self.estimateAttempts = 0
        self.mfToken = ""
        self.isImageTaking = false
    }
}

// Error Handlers
extension PortraitScanViewController {
    func handleFaceStatus(faceStatus: Int, isAntispoof: Bool = false, isHoldStill: Bool = true, image: UIImage) {
        let isFailure = faceStatus != 0
        if isFailure {
            self.estimateAttempts = 0
            self.circularProgressView.progress = 0.0
            self.changeResultLabel(attributedText: NSAttributedString(string: "0%" + " " + "recognised".localized,
                                                                      attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            
            if faceStatus == 10 && FlowManager.shared.current == .enroll {
                UIImage.saveImageLocally(image: image, fileName: UUID().uuidString)
                self.changeTitle(attributedText: NSAttributedString(string: "remove.glasses".localized,
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            }
        }
        
        if (FlowManager.shared.current == .signIn && faceStatus == 10) ||
            (FlowManager.shared.current == .matchFace && faceStatus == 10) {
            self.focusCamera()
        }
        
        if isAntispoof {
            switch faceStatus {
            case -100, -5, -4, -2, 1:
                self.changeTitle(attributedText: NSAttributedString(string: "increase.lighting".localized,
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case -3:
                self.changeTitle(attributedText: NSAttributedString(string: "face.into.circle".localized,
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case -1:
                self.changeTitle(attributedText: NSAttributedString(string: "looking.for.face".localized,
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            default: break
            }
            
        } else {
            switch faceStatus {
            case -100, -1:
                self.changeTitle(attributedText: NSAttributedString(string: "center.your.head".localized,
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case 0:
                self.focusCamera()
                if isHoldStill {
                    self.changeTitle(attributedText: NSAttributedString(string: "Processing hold still",
                                                                        attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
                }
            case 1, 2, 3:
                self.changeTitle(attributedText: NSAttributedString(string: "Please move back",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case 4:
                self.changeTitle(attributedText: NSAttributedString(string: "Please move closer",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case 5:
                self.changeTitle(attributedText: NSAttributedString(string: "Move slightly left",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case 6:
                self.changeTitle(attributedText: NSAttributedString(string: "Move slightly right",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case 7:
                self.changeTitle(attributedText: NSAttributedString(string: "Move your head down",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case 8:
                self.changeTitle(attributedText: NSAttributedString(string: "Move your head up",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case 9:
                self.changeTitle(attributedText: NSAttributedString(string: "Please hold still",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case 10:
                guard FlowManager.shared.current != .signIn,
                      FlowManager.shared.current != .matchFace else { return }
                UIImage.saveImageLocally(image: image, fileName: UUID().uuidString)
                self.changeTitle(attributedText: NSAttributedString(string: "Remove glasses",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case 11:
                self.changeTitle(attributedText: NSAttributedString(string: "Remove mask",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case 12, 13:
                self.changeTitle(attributedText: NSAttributedString(string: "Please look at camera",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case 14:
                self.changeTitle(attributedText: NSAttributedString(string: "Raise phone level to face",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case 15:
                self.changeTitle(attributedText: NSAttributedString(string: "Lower phone level to face",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case 16:
                self.changeTitle(attributedText: NSAttributedString(string: "Too dim - increase lighting",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case 17:
                self.changeTitle(attributedText: NSAttributedString(string: "Too bright - lower lighting",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case 18:
                self.changeTitle(attributedText: NSAttributedString(string: "Please hold still",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case 19:
                self.changeTitle(attributedText: NSAttributedString(string: "",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case 20:
                self.changeTitle(attributedText: NSAttributedString(string: "Please hold still",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case 21:
                self.changeTitle(attributedText: NSAttributedString(string: "Please close mouth",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            case 22, 23:
                self.changeTitle(attributedText: NSAttributedString(string: "Please straighten head",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            default:
                self.changeTitle(attributedText: NSAttributedString(string: "",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black]))
            }
        }
    }
    
    func showFaceID() {
        guard isFaceIdRunning == false else { return }
        self.isFaceIdRunning = true
        
        faceIDStartTime = Date()
        
        CryptonetManager.shared.authenticateWithFaceIDWithoutPasscode { [weak self] isAllowed, error in
            guard let self = self else { return }
            
            var isValidated: Bool = true
            
            if let startTime = self.faceIDStartTime {
                self.faceIDExecutionTime = Date().timeIntervalSince(startTime)
                print("FaceID execution time: \(self.faceIDExecutionTime) seconds")
                
                if self.faceIDExecutionTime > faceIDDurationTime {
                    isValidated = false
                }
            }
            
            self.isFaceIdRunning = false
            self.faceIDStartTime = nil
            
            if isAllowed == false || isValidated == false {
                self.reset()
            }
        }
    }
    
    func startScanSession() {
        showFaceID()
        guard self.sessionStartTime == nil else { return }
        sessionStartTime = Date()
    }
    
    func finishedScanSession() {
        var isValidated: Bool = true
        
        if let startTime = self.sessionStartTime {
            self.sessionExecutionTime = Date().timeIntervalSince(startTime)
            print("FaceID execution time: \(self.sessionExecutionTime) seconds")
            
            if self.sessionExecutionTime > sessionDurationTime {
                isValidated = false
            }
        }
        
        self.sessionStartTime = nil
        
        if isValidated == false {
            self.reset()
        }
    }
}
