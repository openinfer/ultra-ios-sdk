import UIKit
import AVFoundation
import CoreMedia
import Toaster
import ProgressHUD

final class ScanViewController: BaseViewController {
    
    @IBOutlet weak var portraitContainer: UIView!
    @IBOutlet weak var portraitVideoFrame: UIView!
    @IBOutlet weak var portraitVideoContainer: UIView!
    @IBOutlet weak var portraitTitleLabel: UILabel!
    @IBOutlet weak var portraitResultLabel: UILabel!
    @IBOutlet weak var portraitActivityLoading: UIActivityIndicatorView!
    @IBOutlet weak var portraitFooterContainer: UIView!
    @IBOutlet weak var portraitLockImage: UIImageView!
    @IBOutlet weak var portraitFaceIdImage: UIImageView!
    @IBOutlet weak var portraitCircularProgressView: CircularProgressView!
    
    @IBOutlet weak var landscapeContainer: UIView!
        
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
            self.portraitResultLabel.attributedText = NSAttributedString(string: "\(Int(newValue))%" + " " + "recognised".localized,
                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
        }
    }
    var mfToken: String = ""
    var isFaceScanFailed: Bool = true
    var isFocused: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        self.portraitTitleLabel.attributedText = NSAttributedString(string: "center.your.head".localized,
                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
//        self.faceIdImage.isHidden = FlowManager.shared.scanType != .face
        footer.delegate = self
        portraitFooterContainer.addSubview(footer)
        
        ToastView.appearance().bottomOffsetPortrait = self.view.frame.height - 150.0
        ToastView.appearance().font = UIFont.systemFont(ofSize: 16)

        setupProgress()
        checkOrientationUI()
        NotificationCenter.default.addObserver(self, selector: #selector(checkOrientationUI), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        CryptonetManager.shared.startDeviceInfoCollect(with: self.cameraLunchTime)
        if isCameraRunning == false {
            isCameraRunning = true
            setupCamera()
            setupTimer()
            launchFaceId()
            updateOrientationSettings()
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
        footer.frame = portraitFooterContainer.bounds
        previewLayer?.frame = portraitVideoFrame.layer.bounds
    }
    
    // MARK:- Actions
    
    @objc func checkOrientationUI() {
        let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
        
        let isPortrait = orientation?.isPortrait == true
        let isLandscape = orientation?.isLandscape == true

        portraitContainer.isHidden = !isPortrait
        landscapeContainer.isHidden = !isLandscape
        
        updateOrientationSettings()
    }
    
    @objc func backToRoot() {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @IBAction func backTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func captureVideoFrame() {
        DispatchQueue.main.async {
            if let image = self.tempImage {
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
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
//                let link = CryptonetManager.shared.redirectURL ?? "https://www.google.com/"
//                UIApplication.openIfPossible(link: link)
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { exit(0) }
//            }
        }
    }
    
    func updateCounter(currentValue: Int, toValue: Double) {
        if currentValue <= Int(toValue * 100) {
                self.portraitResultLabel.attributedText = NSAttributedString(string: "\(currentValue)%" + " " + "recognised".localized,
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
                self.portraitCircularProgressView.alpha = 0.0
                self.portraitVideoFrame.transform = CGAffineTransform(scaleX: 0.0001, y: 0.0001)
            }, completion: { _ in
//                self.activityLoading.startAnimating()
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
    
    func launchFaceId() {
        UIView.animate(withDuration: 0.15, delay: 0.7, animations: {
            self.portraitFaceIdImage.transform = CGAffineTransform(translationX: 0, y: -10) // Move up
        }) { _ in
            UIView.animate(withDuration: 0.15, animations: {
                self.portraitFaceIdImage.transform = .identity
                
                CryptonetManager.shared.authenticateWithFaceIDWithoutPasscode { isAllowed, error in
                    if isAllowed {
                        self.startSession()
                        self.portraitFaceIdImage.isHidden = true
                    } else {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                            ProgressHUD.failed("Passwrod entrance is not available.")
                        }
        
                        self.reset()
                    }
                }
            })
        }
    }
    
    func setupProgress() {
        portraitCircularProgressView.rounded = false
        portraitCircularProgressView.progressColor = .systemGreen
        portraitCircularProgressView.trackColor = .white
        portraitCircularProgressView.alpha = 0.0
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
            previewLayer?.frame = portraitVideoFrame.layer.bounds
            portraitVideoFrame.layer.addSublayer(previewLayer!)
            
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
