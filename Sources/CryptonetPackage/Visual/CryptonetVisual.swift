import UIKit
import AVFoundation
import CoreMedia

public class CryptonetVisual: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    @IBOutlet weak var videoFrame: UIView!
    @IBOutlet weak var videoContainer: UIView!
    
    private let session = AVCaptureSession()
    private var previewLayer: AVCaptureVideoPreviewLayer?
    
    public override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        setupCamera()
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
            startSession()
        } catch {
            print(error.localizedDescription)
        }
    }
    
    func startSession() {
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
            }
        }
    }
}
