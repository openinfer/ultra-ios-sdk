import UIKit
import ProgressHUD
import AVFoundation
import SwiftyGif

class FaceInstructionViewController: UIViewController {
    
    @IBOutlet weak var instructionImageView: UIImageView!
    @IBOutlet weak var footerContainer: UIView!
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var glassesImage: UIImageView!
    @IBOutlet weak var lightImage: UIImageView!
    @IBOutlet weak var frameImage: UIImageView!
    private let footer: FooterView = .fromNib()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mainImage.image = UIImage(named: "step-1")
        glassesImage.image = UIImage(named: "sentence-1")
        lightImage.image = UIImage(named: "sentence-3")
        frameImage.image = UIImage(named: "sentence-2")
        
        let url = URL(string: "https://i.ibb.co/7Yc6400/Scan-face.gif")
        let loader = UIActivityIndicatorView(style: .medium)
        
        instructionImageView.setGifFromURL(url!, levelOfIntegrity: .lowForManyGifs, customLoader: loader)
        instructionImageView.startAnimatingGif()
        footerContainer.addSubview(footer)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        footer.frame = footerContainer.bounds
    }
    
    @IBAction func nextTapped(sender: UIButton) {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { response in
            if response {
                DispatchQueue.main.async { [unowned self] in
                    self.nextIfModelsReady()
                }
            } else {
                self.showAlertForDeclinedRequest()
            }
        }
    }
    
    private func nextIfModelsReady() {
        proceed()
    }
    
    private func proceed() {
        let storyboard = UIStoryboard(name: "CryptonetVisual", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "ScanViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showAlertForDeclinedRequest() {
        DispatchQueue.main.async { [unowned self] in
            let alert = UIAlertController(title: "Camera usage is not allowed.",
                                          message: "Please, allow camera usage in Settings.", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Go to settings", style: .default, handler:{ (UIAlertAction) in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }

                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                }
            }))
            alert.addAction(UIAlertAction(title: "Exit", style: .default, handler:{ (UIAlertAction) in
                self.navigationController?.popToRootViewController(animated: true)
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
}
