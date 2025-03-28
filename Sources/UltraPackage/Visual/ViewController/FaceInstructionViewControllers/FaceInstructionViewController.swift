import UIKit
import ProgressHUD
import AVFoundation
import SwiftyGif
import LocalAuthentication

class FaceInstructionViewController: BaseViewController {
    
    @IBOutlet weak var instructionImageView: UIImageView!
    @IBOutlet weak var footerContainer: UIView!
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var glassesImage: UIImageView!
    @IBOutlet weak var lightImage: UIImageView!
    @IBOutlet weak var frameImage: UIImageView!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var mainTitle: UILabel!
    @IBOutlet weak var subTitle: UILabel!
    @IBOutlet weak var glassesTitle: UILabel!
    @IBOutlet weak var glassesSubtitle: UILabel!
    @IBOutlet weak var backgroundTitle: UILabel!
    @IBOutlet weak var backgroundSubtitle: UILabel!
    @IBOutlet weak var ligthTitle: UILabel!
    @IBOutlet weak var lightSubtitle: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    private let footer: FooterView = .fromNib()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let url = URL(string: "https://i.ibb.co/7Yc6400/Scan-face.gif")
        let loader = UIActivityIndicatorView(style: .medium)
        
        instructionImageView.setGifFromURL(url!, levelOfIntegrity: .lowForManyGifs, customLoader: loader)
        instructionImageView.startAnimatingGif()
        footer.delegate = self
        footerContainer.addSubview(footer)
        
        self.mainTitle.text = "verify.identity.selfie.message".localized
        self.subTitle.text = "verify.identity.selfie.message2".localized
        self.glassesTitle.text = "take.off.glasses".localized
        self.glassesSubtitle.text = "ensure.nothing.covers.face".localized
        self.backgroundTitle.text = "ensure.good.lighting".localized
        self.backgroundSubtitle.text = "your.face.backlit.light.source".localized
        self.ligthTitle.text = "uncluttered.backgrounds".localized
        self.lightSubtitle.text = "ensure.face.in.frame".localized
        self.startButton.setTitle("start".localized, for: .normal)
        
        setUpCloseButton()
        self.startButton.alpha = 0.6
        self.startButton.isUserInteractionEnabled = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.startButton.alpha = 1.0
            self.startButton.isUserInteractionEnabled = true
            self.activityIndicator.stopAnimating()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
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
        self.proceed()
    }
    
    private func proceed() {
        let storyboard = UIStoryboard(name: "ScanViewController", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "MainScanViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    private func showAlertForDeclinedRequest() {
        DispatchQueue.main.async { [unowned self] in
            let alert = UIAlertController(title: "camera.usage.is.not.allowed".localized,
                                          message: "allow.camera.usage.in.settings".localized, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "go.to.settings".localized, style: .default, handler:{ (UIAlertAction) in
                guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                    return
                }
                
                if UIApplication.shared.canOpenURL(settingsUrl) {
                    UIApplication.shared.open(settingsUrl, completionHandler: nil)
                }
            }))
            alert.addAction(UIAlertAction(title: "exit".localized, style: .default, handler:{ (UIAlertAction) in
                self.navigationController?.popToRootViewController(animated: true)
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
}

extension FaceInstructionViewController: FooterViewDelegate {
    func feedbackTapped() {
        let storyboard = UIStoryboard(name: "FeedbackViewController", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "FeedbackViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
