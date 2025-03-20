import UIKit
import Alamofire
import ProgressHUD

final class VerifyingViewController: BaseViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var footerContainer: UIView!
//    
    private var sessionModel: SessionDetailsModel?
    
    private let footer: FooterView = .fromNib()
    
    var isVerified = false
    var isSucced = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: true)
        titleLabel.text = "wait.a.sec".localized
        footer.delegate = self
        footerContainer.addSubview(footer)
        imageView.setGifFromURL(URL(string: "https://i.ibb.co/8Jx4hTm/Face-ID.gif")!, levelOfIntegrity: .lowForManyGifs, customLoader: UIActivityIndicatorView(style: .medium))
        CryptonetManager.shared.resetSession()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            if self.isSucced {
                NetworkManager.shared.fetchSessionDetails { [weak self] model in
                    guard let self = self else { return }
                    self.finish()
                }
            } else {
                self.reset()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        footer.frame = footerContainer.bounds
    }
    
    @IBAction func homeTapped() {
        reset()
    }
    
    @IBAction func saveUUIDTapped() {
        guard let uuid = self.sessionModel?.identificationResult?.uuid else {
            ProgressHUD.failed("No active UUID")
            return
        }
        
        UIPasteboard.general.string = uuid
        ProgressHUD.succeed("UUID is copied")
    }
}

extension VerifyingViewController {
    func finish() {
        if let universalLink = CryptonetManager.shared.universalLink, let url = URL(string: universalLink) {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        } else {
            self.reset()
        }
    }
    
    func showSuccessPage() {
        imageView.image = UIImage.SPMImage(named: "success")
        titleLabel.text = isVerified ? "account.is.verified".localized : "account.is.registered".localized
    }
    
    func showFailurePage() {
        imageView.image = UIImage.SPMImage(named: "failure")
        titleLabel.text = "account.is.not.approved".localized
    }
    
    func showFailureSession() {
        imageView.image = UIImage.SPMImage(named: "failure")
        titleLabel.text = "session.was.failed".localized
    }
}

extension VerifyingViewController: FooterViewDelegate {
    func feedbackTapped() {
        let storyboard = UIStoryboard(name: "CryptonetVisual", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "FeedbackViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
