import UIKit
import AVFoundation
import CoreMedia
import Toaster
import ProgressHUD

final class ScanViewController: BaseViewController {

    @IBOutlet weak var videoFrame: UIView!
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var successContainer: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var confettiImageView: UIImageView!
    @IBOutlet weak var activityLoading: UIActivityIndicatorView!
    
    @IBOutlet weak var footerContainer: UIView!
    @IBOutlet weak var lockImage: UIImageView!
    @IBOutlet weak var faceIdImage: UIImageView!
    
    @IBOutlet weak var headerHeight: NSLayoutConstraint!
    @IBOutlet weak var footerHeight: NSLayoutConstraint!
    @IBOutlet weak var centerHeight: NSLayoutConstraint!
    
    private let footer: FooterView = .fromNib()
    
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var currentOrientation: AVCaptureVideoOrientation = .portrait
    private var timer: Timer?
    private var timeInterval: TimeInterval = 0.3
    private var tempImage: UIImage?
    private var isCameraRunning = false
    private var cameraStartTime: Date?
    private var cameraLunchTime: String = ""
    
    var faceAnimationTimer: Timer?
    var faceAnimationTimeInterval: TimeInterval = 1.5
    
    var sessionTimer: Timer?
    var sessionTimeInterval: TimeInterval = 1.0
    var sessionCountdown: Int = 45

    var nextStepForFlows: String?
    var isScanSuccess: Bool = false
    var failureTimes = 0
    var token: String? = nil
    var isImageProcessing: Bool = false
    var isPredictRunning: Bool = false
    var isEnrollRunning: Bool = false
    var isDocumentScan: Bool = false
    var estimateAttempts: Float = 0.0 {
        willSet {
            self.resultLabel.attributedText = NSAttributedString(string: "\(Int(newValue))%" + " " + "recognised".localized,
                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
        }
    }
    var mfToken: String = ""
    var isFaceScanFailed: Bool = true
    var isFocused: Bool = false
    
    var circularProgressView: CircularProgressView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.titleLabel.attributedText = NSAttributedString(string: "center.your.head".localized,
                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
//        self.faceIdImage.isHidden = FlowManager.shared.scanType != .face
        footer.delegate = self
        footerContainer.addSubview(footer)
        
        ToastView.appearance().bottomOffsetPortrait = self.view.frame.height - 150.0
        ToastView.appearance().font = UIFont.systemFont(ofSize: 16)
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CryptonetManager.shared.startDeviceInfoCollect(with: self.cameraLunchTime)
        orientationChanged()
        if isCameraRunning == false {
            isCameraRunning = true
            setupCamera()
            setupTimer()
//            startFaceAnimationTimer()
//            if FlowManager.shared.scanType == .face {
                UIView.animate(withDuration: 0.15, delay: 0.3, animations: {
                    self.faceIdImage.transform = CGAffineTransform(translationX: 0, y: -10) // Move up
                }) { _ in
                    UIView.animate(withDuration: 0.15, animations: {
                        self.faceIdImage.transform = .identity
                        
                        CryptonetManager.shared.authenticateWithFaceIDWithoutPasscode { isAllowed, error in
                            if isAllowed {
                                self.startSession()
                                self.faceIdImage.isHidden = true
                            } else {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                    ProgressHUD.failed("Passwrod entrance is not available.")
                                }
                
                                self.reset()
                            }
                        }
                    })
                }
//            } else {
//                self.startSession()
//            }
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
//        stopFaceAnimationTimer()
        stopSession()
        stopSessionTimer()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        footer.frame = footerContainer.bounds
        if circularProgressView == nil {
            let lineWidth: Double = 8
            circularProgressView = CircularProgressView(frame: CGRect(x: 0 + (lineWidth / 2),
                                                              y: 0 + (lineWidth / 2),
                                                              width: videoContainer.frame.width - lineWidth * 2,
                                                              height: videoContainer.frame.height - lineWidth * 2),
                                                              lineWidth: lineWidth, rounded: false,
                                                         isRectAnimation: false, isDahsed: true)
            circularProgressView?.progressColor = .systemGreen
            circularProgressView?.trackColor = .white
            circularProgressView?.alpha = 0.0
            videoContainer.addSubview(circularProgressView!)
        }
        
        previewLayer?.frame = videoFrame.layer.bounds
    }
    
    // MARK:- Actions
    
    @objc func orientationChanged() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if UIDevice.current.userInterfaceIdiom == .pad  {
                self.centerHeight.constant = self.view.frame.width / 2
            } else {
                switch UIDevice.current.orientation {
                case .portrait:
                    self.headerHeight.constant = 40.0
                    self.footerHeight.constant = 80.0
                    self.centerHeight.constant = self.view.frame.width / 1.3
                    self.navigationController?.setNavigationBarHidden(false, animated: true)
                case .landscapeLeft, .landscapeRight, .portraitUpsideDown:
                    self.headerHeight.constant = 00.0
                    self.footerHeight.constant = 00.0
                    self.centerHeight.constant = self.view.frame.height / 1.4
                    self.navigationController?.setNavigationBarHidden(true, animated: true)
                default: break
                }
                
                UIView.animate(withDuration: 0.3) {
                    self.view.layoutIfNeeded()
                }
            }
        }
        
        updateOrientationSettings()
    }
    
    @objc func backToRoot() {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func captureVideoFrame() {
        DispatchQueue.main.async {
            if let image = self.tempImage {
                self.scan(with: image)
            }
        }
    }
    
    @objc func faceAnimationCircule() {
        DispatchQueue.main.async {
            self.circularProgressView?.progressColor = self.isFaceScanFailed ? UIColor.white : UIColor.green
            let isFinished = self.circularProgressView?.progressColor == UIColor.green && self.circularProgressView?.progress == 1.0
            guard isFinished == false else { return }
            if self.circularProgressView?.progressColor == UIColor.green {
                self.updateCounter(currentValue: 0, toValue: 1.0)
            } else {
                self.resultLabel.attributedText = NSAttributedString(string: "0%" + " " + "recognised".localized,
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            }
           
            self.circularProgressView?.progress = 0.0
            self.circularProgressView?.timeToFill = 1.5
            self.circularProgressView?.progress = 1.0
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
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                let link = CryptonetManager.shared.redirectURL ?? "https://www.google.com/"
//                UIApplication.openIfPossible(link: link)
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { exit(0) }
//            }
        }
    }
    
    func updateCounter(currentValue: Int, toValue: Double) {
        if currentValue <= Int(toValue * 100) {
                self.resultLabel.attributedText = NSAttributedString(string: "\(currentValue)%" + " " + "recognised".localized,
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            let dispatchTime: DispatchTime = DispatchTime.now() + Double(Int64(0.01 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
            DispatchQueue.main.asyncAfter(deadline: dispatchTime, execute: {
                self.updateCounter(currentValue: currentValue + 1, toValue: toValue)
            })
        }
    }
    
    @IBAction func doneTapped(sender: UIButton) {
        // TODO:
    }
    
    // MARK:- Setup state
    
    func setupTimer() {
        timer = Timer.scheduledTimer(timeInterval: timeInterval, target: self, selector: #selector(captureVideoFrame), userInfo: nil, repeats: true)
    }
    
    func startFaceAnimationTimer() {
        faceAnimationTimer = Timer.scheduledTimer(timeInterval: faceAnimationTimeInterval, target: self, selector: #selector(faceAnimationCircule), userInfo: nil, repeats: true)
    }
    
    func stopFaceAnimationTimer() {
        faceAnimationTimer?.invalidate()
        faceAnimationTimer = nil
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
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }
    
    func stopSession() {
        if session.isRunning {
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
                self.circularProgressView?.alpha = 0.0
                self.videoContainer.transform = CGAffineTransform(scaleX: 0.0001, y: 0.0001)
            }, completion: { _ in
//                self.activityLoading.startAnimating()
            })
    }
    
    
//    func liveIconSucceed(_ view: UIView) {
//        let url = URL(string: "https://i.ibb.co/3pnnYyR/Confetti.gif")
//        let loader = UIActivityIndicatorView(style: .medium)
//        self.confettiImageView.setGifFromURL(url!, customLoader: loader)
//        self.activityLoading.stopAnimating()
//    }
    
    func liveIconSucceed(_ view: UIView) {
        let length = view.frame.width

        let path = UIBezierPath()
        path.move(to: CGPoint(x: length * 0.15, y: length * 0.50))
        path.addLine(to: CGPoint(x: length * 0.5, y: length * 0.80))
        path.addLine(to: CGPoint(x: length * 1.0, y: length * 0.25))

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = 0.25
        animation.fromValue = 0
        animation.toValue = 1
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false
        animation.beginTime = CACurrentMediaTime()

        let layer = CAShapeLayer()
        layer.path = path.cgPath
        layer.fillColor = UIColor.clear.cgColor
        layer.strokeColor = UIColor.gray.cgColor
        layer.lineWidth = 9
        layer.lineCap = .round
        layer.lineJoin = .round
        layer.strokeEnd = 0

        layer.add(animation, forKey: "animation")
        view.layer.addSublayer(layer)
    }
    
    func showFailedAnimation() {
        UIView.animate(
            withDuration: 0.5,
            animations: {
                self.videoContainer.transform = CGAffineTransform(scaleX: 0.0001, y: 0.0001)
            },
            completion: { _ in
                self.liveIconFailed(self.successContainer)
            })
    }
    
    func navigateToFinalWithFailure() {
        let storyboard = UIStoryboard(name: "CryptonetVisual", bundle: Bundle.module)
        if let vc = storyboard.instantiateViewController(withIdentifier: "VerifyingViewController") as? VerifyingViewController {
            vc.isVerified = false
            vc.isSucced = false
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func navigateToVerifyingPage(isVerified: Bool) {
        let storyboard = UIStoryboard(name: "CryptonetVisual", bundle: Bundle.module)
        if let vc = storyboard.instantiateViewController(withIdentifier: "VerifyingViewController") as? VerifyingViewController {
            vc.isVerified = isVerified
            vc.isSucced = true
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
}

// MARK:- Private
private extension ScanViewController {
    
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
    
    func updateOrientationSettings() {
        guard let connection = previewLayer?.connection, connection.isVideoOrientationSupported else { return }
        
        switch UIDevice.current.orientation {
        case .portrait:
            currentOrientation = .portrait
        case .portraitUpsideDown:
            currentOrientation = .portraitUpsideDown
        case .landscapeLeft:
            currentOrientation = .landscapeRight // Inverted due to camera mirroring
        case .landscapeRight:
            currentOrientation = .landscapeLeft // Inverted due to camera mirroring
        default:
            break
        }
        
        connection.videoOrientation = currentOrientation
    }

    func liveIconFailed(_ view: UIView) {
        let length = view.frame.width
        
        let path1 = UIBezierPath()
        let path2 = UIBezierPath()

        path1.move(to: CGPoint(x: length * 0.15, y: length * 0.15))
        path2.move(to: CGPoint(x: length * 0.15, y: length * 0.85))

        path1.addLine(to: CGPoint(x: length * 0.85, y: length * 0.85))
        path2.addLine(to: CGPoint(x: length * 0.85, y: length * 0.15))

        let paths = [path1, path2]

        let animation = CABasicAnimation(keyPath: "strokeEnd")
        animation.duration = 0.15
        animation.fromValue = 0
        animation.toValue = 1
        animation.fillMode = .forwards
        animation.isRemovedOnCompletion = false

        for i in 0..<2 {
            let layer = CAShapeLayer()
            layer.path = paths[i].cgPath
            layer.fillColor = UIColor.clear.cgColor
            layer.strokeColor = UIColor.gray.cgColor
            layer.lineWidth = 9
            layer.lineCap = .round
            layer.lineJoin = .round
            layer.strokeEnd = 0

            animation.beginTime = CACurrentMediaTime() + 0.25 * Double(i)

            layer.add(animation, forKey: "animation")
            view.layer.addSublayer(layer)
        }
    }
}

// MARK:- AVCaptureVideoDataOutputSampleBufferDelegate
extension ScanViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if let startTime = cameraStartTime {
            let elapsedTime = Date().timeIntervalSince(startTime)
            print("Camera launch time: \(elapsedTime) seconds")
            self.cameraLunchTime = "\(elapsedTime) seconds"
            cameraStartTime = nil // Reset to avoid multiple prints
        }
        DispatchQueue.global(qos: .userInitiated).async {
            connection.videoOrientation = self.currentOrientation
            let imageBuffer: CVPixelBuffer = sampleBuffer.imageBuffer!
            let ciimage: CIImage = CIImage(cvPixelBuffer: imageBuffer)
            let image: UIImage = self.convert(cmage: ciimage)
            print("Image: \(image.size)")
            self.tempImage = self.cropImageToSquare(image: image)
        }
    }
    
    private func cropImageToSquare(image: UIImage) -> UIImage? {
        var imageHeight = image.size.height
        var imageWidth = image.size.width
        
        if imageHeight > imageWidth {
            imageHeight = imageWidth
        }
        else {
            imageWidth = imageHeight
        }
        
        let size = CGSize(width: imageWidth, height: imageHeight)
        
        let refWidth : CGFloat = CGFloat(image.cgImage!.width)
        let refHeight : CGFloat = CGFloat(image.cgImage!.height)
        
        let x = (refWidth - size.width) / 2
        let y = (refHeight - size.height) / 2
        
        let cropRect = CGRect(x: x, y: y, width: size.height, height: size.width)
        if let imageRef = image.cgImage!.cropping(to: cropRect) {
            return UIImage(cgImage: imageRef, scale: 0, orientation: image.imageOrientation)
        }
        
        return nil
    }
    
    private func convert(cmage:CIImage) -> UIImage {
        let context: CIContext = CIContext()
        let cgImage: CGImage = context.createCGImage(cmage, from: cmage.extent)!
        let image:UIImage = UIImage.init(cgImage: cgImage)
        return image
    }
}

extension ScanViewController: FooterViewDelegate {
    func feedbackTapped() {
        let storyboard = UIStoryboard(name: "CryptonetVisual", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "FeedbackViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
