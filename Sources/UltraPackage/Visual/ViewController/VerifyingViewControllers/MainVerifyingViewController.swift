import UIKit

final class MainVerifyingViewController: BaseViewController {
    
    @IBOutlet weak var portraitContainer: UIView!
    @IBOutlet weak var landscapeContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkOrientationUI()
        NotificationCenter.default.addObserver(self, selector: #selector(checkOrientationUI), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
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
}
