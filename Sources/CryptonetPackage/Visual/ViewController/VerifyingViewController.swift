import UIKit
import Alamofire
import ProgressHUD

final class VerifyingViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var copyUUIDButton: UIButton!
    @IBOutlet weak var footerContainer: UIView!
//    
    private var sessionModel: SessionDetailsModel?
    
    private let footer: FooterView = .fromNib()
    
    var isVerified = false
    var isSucced = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: true)
        footer.delegate = self
        footerContainer.addSubview(footer)
        if isSucced {
            fetchSessionDetails()
        } else {
            showFailureSession()
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        footer.frame = footerContainer.bounds
    }
    
    @IBAction func homeTapped() {
        self.navigationController?.popToRootViewController(animated: true)
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
    func fetchSessionDetails() {
        guard let token = CryptonetManager.shared.sessionToken else { return }
        guard let url = URL(string: "https://api-orchestration-privateid.uberverify.com/v2/verification-session/\(token)/webhook-payload") else { return }
        

        let headers: HTTPHeaders = [
            "Content-Type": "application/json"
        ]
        
        AF.request(url, method: .get, encoding: JSONEncoding.default, headers: headers)
            .validate()
            .responseDecodable(of: SessionDetailsModel.self) { response in
                switch response.result {
                case .success(let model):
                    self.sessionModel = model
                    self.showSuccessPage()
                case .failure:
                    self.showFailurePage()
                }
            }
    }
    
    func showSuccessPage() {
        imageView.image = UIImage(named: "success")
        titleLabel.text = isVerified ? "Your account is verified!" : "Your account is registered!"
        homeButton.isHidden = false
    }
    
    func showFailurePage() {
        imageView.image = UIImage(named: "failure")
        titleLabel.text = "Your account is not approved."
        homeButton.isHidden = false
    }
    
    func showFailureSession() {
        imageView.image = UIImage(named: "failure")
        titleLabel.text = "Your session was failed. Try to run the app again."
        homeButton.isHidden = false
    }
}

extension VerifyingViewController: FooterViewDelegate {
    func feedbackTapped() {
        let storyboard = UIStoryboard(name: "CryptonetVisual", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "FeedbackViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
