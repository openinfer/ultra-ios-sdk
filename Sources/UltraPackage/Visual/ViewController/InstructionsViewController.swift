import UIKit

final class InstructionsViewController: BaseViewController, UITextViewDelegate {
    
    @IBOutlet weak var mainTitle: UILabel!
    @IBOutlet weak var termsTextView: UITextView!
    @IBOutlet weak var agreeButton: UIButton!
    @IBOutlet weak var backOptionButton: UIButton!
    @IBOutlet weak var footerContainer: UIView!
    @IBOutlet weak var mainImage: UIImageView!
    
    @IBOutlet weak var footerHeight: NSLayoutConstraint!
    @IBOutlet weak var centerImageHeight: NSLayoutConstraint!
    
    private let footer: FooterView = .fromNib()
    
    private let tappableTexts = ["verify.identity.privacy.policy".localized, "verify.identity.privacy.terms".localized, "learn_word".localized]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: true)
        footer.delegate = self
        footerContainer.addSubview(footer)
        setupTermsTextView()
        
        self.mainTitle.text = "Take a selfie to register." // TODO:
        self.agreeButton.setTitle("privacy.agree.continue.button".localized, for: .normal)
        self.backOptionButton.setTitle("noThanks".localized, for: .normal)
        adjustOrientation()
        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        footer.frame = footerContainer.bounds
    }
    
    // MARK: - Actions
    
    @IBAction func confirmTapped() {
        let identifier = "FaceInstructionViewController"
        let storyboard = UIStoryboard(name: "CryptonetVisual", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: identifier)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func backTapped() {
        DispatchQueue.main.async { [unowned self] in
            let alert = UIAlertController(title: "confirmation_title".localized,
                                          message: "confirmation_message".localized, preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "ok".localized, style: .default, handler:{ (UIAlertAction) in
                self.navigationController?.popToRootViewController(animated: true)
            }))
            alert.addAction(UIAlertAction(title: "cancel".localized, style: .cancel, handler:{ (UIAlertAction) in
                
            }))
            
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func setupTermsTextView() {
        let fullText = """
        By clicking the 'Agree and continue' button below, you acknowledge that you are over eighteen (18) years of age, have read the Private Identity Privacy Policy and Terms of Use and understand how your personal data will be processed in connection with your use of this Identity Verification Service.

        Learn how identity verification works.
        """

        let attributedString = NSMutableAttributedString(string: fullText)

        let privacyPolicyRange = (fullText as NSString).range(of: "Privacy Policy")
        let termsOfUseRange = (fullText as NSString).range(of: "Terms of Use")
        let learnRange = (fullText as NSString).range(of: "Learn")

        // Apply link attributes
        attributedString.addAttribute(.link, value: CryptonetManager.privacyURL, range: privacyPolicyRange)
        attributedString.addAttribute(.link, value: CryptonetManager.termsURL, range: termsOfUseRange)
        attributedString.addAttribute(.link, value: CryptonetManager.learnURL, range: learnRange)

        // Center align text
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, fullText.count))

        // Set UITextView properties
        termsTextView.attributedText = attributedString
        termsTextView.delegate = self
        termsTextView.isEditable = false
        termsTextView.isScrollEnabled = false
        termsTextView.isSelectable = true
        termsTextView.textAlignment = .center
        termsTextView.backgroundColor = .clear
        termsTextView.linkTextAttributes = [
            .foregroundColor: UIColor.black,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
    }

    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        return false // Prevent default behavior
    }
    
    @objc func orientationChanged() {
        adjustOrientation()
    }
    
    func adjustOrientation() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if UIDevice.current.userInterfaceIdiom != .pad  {
                switch UIDevice.current.orientation {
                case .portrait:
                    self.footerHeight.constant = 80.0
                    self.centerImageHeight.constant = self.view.frame.width / 2
                case .landscapeLeft, .landscapeRight, .portraitUpsideDown:
                    self.footerHeight.constant = 0.0
                    self.centerImageHeight.constant = self.view.frame.height / 4
                default: break
                }
            }

            UIView.animate(withDuration: 0.1) {
                self.view.layoutIfNeeded()
            }
        }
    }
}

extension InstructionsViewController: FooterViewDelegate {
    func feedbackTapped() {
        let storyboard = UIStoryboard(name: "CryptonetVisual", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "FeedbackViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
