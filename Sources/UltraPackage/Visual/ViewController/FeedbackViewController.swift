import UIKit
import Alamofire
import ProgressHUD

final class FeedbackViewController: UIViewController {
    
    enum FeedbackEnum: String {
      case delight = "Delight"
      case happy = "Happy"
      case sad = "Sad"
      case frustration = "Frustration"
    }
    
    @IBOutlet weak var footerContainer: UIView!
    private let footer: FooterView = .fromNib()
    
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var mainTitle: UILabel!
    
    @IBOutlet weak var delightButton: UIButton!
    @IBOutlet weak var happyButton: UIButton!
    @IBOutlet weak var sadButton: UIButton!
    @IBOutlet weak var frustrationButton: UIButton!
    
    @IBOutlet weak var delightLabel: UILabel!
    @IBOutlet weak var happyLabel: UILabel!
    @IBOutlet weak var sadLabel: UILabel!
    @IBOutlet weak var frustrationLabel: UILabel!
    
    @IBOutlet weak var returnHome: UIButton!
    @IBOutlet weak var noThanks: UIButton!
    
    private var feedback: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        footer.delegate = self
        footerContainer.addSubview(footer)
        homeButton.alpha = 0.6
        homeButton.isUserInteractionEnabled = false
        
        mainTitle.text = "rate.your.experience".localized
        delightLabel.text = "delight".localized
        sadLabel.text = "happy".localized
        sadLabel.text = "sad".localized
        frustrationLabel.text = "frustration".localized
        returnHome.setTitle("return.to.homepage".localized, for: .normal)
        noThanks.setTitle("noThanks".localized, for: .normal)
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
        ProgressHUD.animate()
        NetworkManager.shared.sendFeedback(feedback: self.feedback) { [weak self] finished in
            guard let self = self else { return }
            DispatchQueue.main.asyncAfter(deadline: .now()) {
                if finished == true {
                    ProgressHUD.dismiss()
                    CryptonetManager.shared.resetSession()
                    self.navigationController?.popToRootViewController(animated: true)
                } else {
                    ProgressHUD.failed()
                    CryptonetManager.shared.resetSession()
                    self.navigationController?.popToRootViewController(animated: true)
                    
                }
            }
        }
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
        
        
        homeButton.alpha = 1.0
        homeButton.isUserInteractionEnabled = true
    }
}

extension FeedbackViewController: FooterViewDelegate {
    func feedbackTapped() {
        let storyboard = UIStoryboard(name: "CryptonetVisual", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "FeedbackViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
