import UIKit

final class InstructionsViewController: UIViewController {
    
    @IBOutlet weak var mainTitle: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var agreeButton: UIButton!
    @IBOutlet weak var backOptionButton: UIButton!
    @IBOutlet weak var footerContainer: UIView!
    @IBOutlet weak var mainImage: UIImageView!
    private let footer: FooterView = .fromNib()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: true)
        footer.delegate = self
        footerContainer.addSubview(footer)
        
        self.titleLabel.text = "privacy.message2".localized + " " +
                                "verify.identity.privacy.policy".localized + " " +
                                "verify.identity.privacy.and".localized + " " +
                                "verify.identity.privacy.terms".localized + " " +
                                "privacy.message3".localized + "."
        self.subtitleLabel.text = "click.message1".localized + " " +
                                  "click.message2".localized + " " +
                                  "click.message3".localized + ". " +
                                  "verify.identity.selfie.message2".localized
        
        self.titleLabel.underlineWords(words: ["verify.identity.privacy.terms".localized, "verify.identity.privacy.policy".localized])
        self.subtitleLabel.underlineWords(words: ["click.message1".localized + " " +
                                                  "click.message2".localized])
        
        self.mainTitle.text = "verify.identity.selfie.message".localized
        self.agreeButton.setTitle("privacy.agree.continue.button".localized, for: .normal)
        self.backOptionButton.setTitle("noThanks".localized, for: .normal)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        footer.frame = footerContainer.bounds
    }
    
    // MARK: - Actions
    
    @IBAction func confirmTapped() {
        let identifier = "UserConsentViewController"
        let storyboard = UIStoryboard(name: "CryptonetVisual", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: identifier)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func backTapped() {
        self.navigationController?.popToRootViewController(animated: true)
    }
}

extension InstructionsViewController: FooterViewDelegate {
    func feedbackTapped() {
        let storyboard = UIStoryboard(name: "CryptonetVisual", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "FeedbackViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
