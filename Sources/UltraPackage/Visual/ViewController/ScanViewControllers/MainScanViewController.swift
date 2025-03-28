import UIKit
import ProgressHUD

final class MainScanViewController: BaseViewController {
    
    @IBOutlet weak var portraitContainer: UIView!
    @IBOutlet weak var landscapeContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkOrientationUI()
        NotificationCenter.default.addObserver(self, selector: #selector(checkOrientationUI), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showFaceID()
    }
    
    @objc func checkOrientationUI() {
        DispatchQueue.main.async {
            let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
            
            let isPortrait = orientation?.isPortrait == true
            let isLandscape = orientation?.isLandscape == true
            
            self.portraitContainer.isHidden = !isPortrait
            self.landscapeContainer.isHidden = !isLandscape
        }
    }
    
    func showFaceID() {
        UIView.animate(withDuration: 0.15, delay: 0.7, animations: {
//            self.faceIdImage.transform = CGAffineTransform(translationX: 0, y: -10) // Move up
        }) { _ in
            UIView.animate(withDuration: 0.15, animations: {
//                self.faceIdImage.transform = .identity
                
                CryptonetManager.shared.authenticateWithFaceIDWithoutPasscode { isAllowed, error in
                    if isAllowed {
//                        self.faceIdImage.isHidden = true
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
}
