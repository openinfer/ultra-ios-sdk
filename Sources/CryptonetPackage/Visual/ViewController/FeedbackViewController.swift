import UIKit
import Alamofire
import ProgressHUD

final class FeedbackViewController: UIViewController {
    
    @IBOutlet weak var footerContainer: UIView!
    private let footer: FooterView = .fromNib()
    
    @IBOutlet weak var delightButton: UIButton!
    @IBOutlet weak var happyButton: UIButton!
    @IBOutlet weak var sadButton: UIButton!
    @IBOutlet weak var frustrationButton: UIButton!
    
    @IBOutlet weak var delightLabel: UILabel!
    @IBOutlet weak var happyLabel: UILabel!
    @IBOutlet weak var sadLabel: UILabel!
    @IBOutlet weak var frustrationLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        delightButton.setImage(UIImage(named: "delight"), for: .normal)
        happyButton.setImage(UIImage(named: "happy"), for: .normal)
        sadButton.setImage(UIImage(named: "sad"), for: .normal)
        frustrationButton.setImage(UIImage(named: "frustration"), for: .normal)
        footer.delegate = self
        footerContainer.addSubview(footer)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        footer.frame = footerContainer.bounds
    }
    
    @IBAction func noThanksTapped(sender: UIButton) {
        let link = CryptonetManager.shared.redirectURL ?? "https://www.google.com/"
        UIApplication.openIfPossible(link: link)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            exit(0)
        }
    }
    
    @IBAction func homepageTapped(sender: UIButton) {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    
    @IBAction func delightButtonTapped() {
        disableAll()
        delightButton.alpha = 1.0
        delightLabel.alpha = 1.0
    }
    
    @IBAction func happyButtonTapped() {
        disableAll()
        happyButton.alpha = 1.0
        happyLabel.alpha = 1.0
    }
    
    @IBAction func sadButtonTapped() {
        disableAll()
        sadButton.alpha = 1.0
        sadLabel.alpha = 1.0
    }
    
    @IBAction func frustrationButtonTapped() {
        disableAll()
        frustrationButton.alpha = 1.0
        frustrationLabel.alpha = 1.0
    }
    
    private func disableAll() {
        delightButton.alpha = 0.3
        happyButton.alpha = 0.3
        sadButton.alpha = 0.3
        frustrationButton.alpha = 0.3
        
        delightLabel.alpha = 0.3
        happyLabel.alpha = 0.3
        sadLabel.alpha = 0.3
        frustrationLabel.alpha = 0.3
    }
}

extension FeedbackViewController: FooterViewDelegate {
    func feedbackTapped() {
        let storyboard = UIStoryboard(name: "CryptonetVisual", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "FeedbackViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
