import UIKit

final class MainScanViewController: UIViewController {
    
    @IBOutlet weak var portraitContainer: UIView!
    @IBOutlet weak var landscapeContainer: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkOrientationUI()
        NotificationCenter.default.addObserver(self, selector: #selector(checkOrientationUI), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    @objc func checkOrientationUI() {
        let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
        
        let isPortrait = orientation?.isPortrait == true
        let isLandscape = orientation?.isLandscape == true

        portraitContainer.isHidden = !isPortrait
        landscapeContainer.isHidden = !isLandscape
    }
}
