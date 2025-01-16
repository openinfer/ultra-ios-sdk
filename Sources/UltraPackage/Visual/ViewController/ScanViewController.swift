import UIKit
import AVFoundation
import CoreMedia
import Toaster

final class ScanViewController: UIViewController {
    
    @IBOutlet weak var videoFrame: UIView!
    @IBOutlet weak var videoContainer: UIView!
    @IBOutlet weak var successContainer: UIView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var resultLabel: UILabel!
    @IBOutlet weak var subresultLabel: UILabel!
    @IBOutlet weak var confettiImageView: UIImageView!
    @IBOutlet weak var activityLoading: UIActivityIndicatorView!
    
    @IBOutlet weak var barcodeTestView: UIView!
    @IBOutlet weak var barcodeDocStatus: UILabel!
    @IBOutlet weak var barcodeBarcodeStatus: UILabel!
    @IBOutlet weak var footerContainer: UIView!
    @IBOutlet weak var lockImage: UIImageView!
    
    private let footer: FooterView = .fromNib()
    
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var timer: Timer?
    private var timeInterval: TimeInterval = 0.3
    private var tempImage: UIImage?
    private var isCameraRunning = false
    
    var faceAnimationTimer: Timer?
    var faceAnimationTimeInterval: TimeInterval = 1.5

    var nextStepForFlows: String?
    var isScanSuccess: Bool = false
    var failureTimes = 0
    var token: String? = nil
    var isImageProcessing: Bool = false
    var isPredictRunning: Bool = false
    var isEnrollRunning: Bool = false
    var isDocumentScan: Bool = false
    var estimateAttempts: Float = 0
    var mfToken: String? = nil
    var enrollProgress: Double = 0.0
    var isFaceScanFailed: Bool = true
    var isFocused: Bool = false
    
    var circularProgressView: CircularProgressView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: true)
        self.titleLabel.attributedText = NSAttributedString(string: "center.your.head".localized,
                                                                attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
        footer.delegate = self
        footerContainer.addSubview(footer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if isCameraRunning == false {
            isCameraRunning = true
            setupCamera()
            setupTimer()
            startFaceAnimationTimer()
            startSession()
        }
        
        Toast(text: "Hello, world!", delay: Delay.short, duration: Delay.long).show()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopTimer()
//        stopFaceAnimationTimer()
        stopSession()
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
            let isFinished = self.circularProgressView?.progressColor == UIColor.green && self.circularProgressView?.progress == 100
            guard isFinished == false else { return }
            if self.circularProgressView?.progressColor == UIColor.green {
                self.updateCounter(currentValue: 0, toValue: 1.0)
            } else {
                self.subresultLabel.attributedText = NSAttributedString(string: "0%",
                                                                    attributes: [NSAttributedString.Key.foregroundColor: UIColor.black])
            }
           
            self.circularProgressView?.progress = 0.0
            self.circularProgressView?.timeToFill = 1.5
            self.circularProgressView?.progress = 100.0
        }
    }
    
    func updateCounter(currentValue: Int, toValue: Double) {
        if currentValue <= Int(toValue * 100) {
                self.subresultLabel.attributedText = NSAttributedString(string: "\(currentValue)%",
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
    
    func stopTimer() {
        if timer?.isValid == true {
            timer?.invalidate()
            timer = nil
        }
    }
    
    func startSession() {
        if !session.isRunning {
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
    
    
    func liveIconSucceed(_ view: UIView) {
        let url = URL(string: "https://i.ibb.co/3pnnYyR/Confetti.gif")
        let loader = UIActivityIndicatorView(style: .medium)
        self.confettiImageView.setGifFromURL(url!, customLoader: loader)
        self.activityLoading.stopAnimating()
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
        DispatchQueue.global(qos: .userInitiated).async {
            connection.videoOrientation = AVCaptureVideoOrientation.portrait
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
