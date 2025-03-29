import UIKit
import Alamofire
import ProgressHUD

final class PortraitVerifyingViewController: BaseViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var footerContainer: UIView!
//
    private var sessionModel: SessionDetailsModel?
    
    private let footer: FooterView = .fromNib()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        titleLabel.text = "wait.a.sec".localized
        footer.delegate = self
        footerContainer.addSubview(footer)
        imageView.setGifFromURL(URL(string: "https://i.ibb.co/8Jx4hTm/Face-ID.gif")!, levelOfIntegrity: .lowForManyGifs, customLoader: UIActivityIndicatorView(style: .medium))
        CryptonetManager.shared.resetSession()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            NetworkManager.shared.fetchSessionDetails { [weak self] model in
                guard let self = self else { return }
                self.finish()
            }
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        footer.frame = footerContainer.bounds
    }
}

extension PortraitVerifyingViewController {
    func finish() {
        if let universalLink = CryptonetManager.shared.universalLink,
           let url = URL(string: universalLink + "://") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                if UIApplication.shared.applicationState == .active {
                    self.reset()
                }
            }
        } else {
            self.reset()
        }
    }
}

extension PortraitVerifyingViewController: FooterViewDelegate {
    func feedbackTapped() {
        let storyboard = UIStoryboard(name: "FeedbackViewController", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "FeedbackViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
