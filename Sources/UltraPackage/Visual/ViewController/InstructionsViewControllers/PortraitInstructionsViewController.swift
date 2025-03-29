import UIKit

final class PortraitInstructionsViewController: BaseViewController, UITextViewDelegate {
    
    @IBOutlet weak var mainTitle: UILabel!
    @IBOutlet weak var terms: UITextView!
    @IBOutlet weak var agree: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var footerContainer: UIView!
    @IBOutlet weak var mainImage: UIImageView!

    private let footer: FooterView = .fromNib()
    
    private let tappableTexts = ["verify.identity.privacy.policy".localized, "verify.identity.privacy.terms".localized, "learn_word".localized]
    
    override func viewDidLoad() {
        super.viewDidLoad()        
        footer.delegate = self
        footerContainer.addSubview(footer)
        
        mainTitle.text = "Take a selfie to register."  // TODO:
        agree.setTitle("privacy.agree.continue.button".localized, for: .normal)
        backButton.setTitle("noThanks".localized, for: .normal)
        setupTermsTextView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        footer.frame = footerContainer.bounds
    }
    
    // MARK: - Actions
  
    @IBAction func confirmTapped() {
        let storyboard = UIStoryboard(name: "FaceInstructionViewController", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "MainFaceInstructionViewController")
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
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        return false // Prevent default behavior
    }
}

private extension PortraitInstructionsViewController {

    func setupTermsTextView() {
        let attributedString = makeTermsAttributedText()
        adjustTextView(termsTextView: terms, with: attributedString)
    }
    
    func adjustTextView(termsTextView: UITextView, with attributedString: NSAttributedString) {
        termsTextView.attributedText = attributedString
        termsTextView.delegate = self
        termsTextView.isEditable = false
        termsTextView.isScrollEnabled = true
        termsTextView.isSelectable = true
        termsTextView.textAlignment = .center
        termsTextView.backgroundColor = .clear
        termsTextView.linkTextAttributes = [
            .foregroundColor: UIColor.black,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
        termsTextView.adjustsFontForContentSizeCategory = true
        termsTextView.font = UIFont.preferredFont(forTextStyle: .body)
        termsTextView.minimumZoomScale = 1.0
        termsTextView.maximumZoomScale = 1.0
        termsTextView.sizeToFit()
        termsTextView.translatesAutoresizingMaskIntoConstraints = false
        termsTextView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        termsTextView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
    }

    func makeTermsAttributedText() -> NSAttributedString {
        let fullText = """
        By clicking the 'Agree and continue' button below, you acknowledge that you are over eighteen (18) years of age, have read the Private Identity Privacy Policy and Terms of Use and understand how your personal data will be processed in connection with your use of this Identity Verification Service.

        Learn how identity verification works.
        """

        let attributedString = NSMutableAttributedString(string: fullText)

        let privacyPolicyRange = (fullText as NSString).range(of: "Privacy Policy")
        let termsOfUseRange = (fullText as NSString).range(of: "Terms of Use")
        let learnRange = (fullText as NSString).range(of: "Learn")

        attributedString.addAttribute(.link, value: CryptonetManager.privacyURL, range: privacyPolicyRange)
        attributedString.addAttribute(.link, value: CryptonetManager.termsURL, range: termsOfUseRange)
        attributedString.addAttribute(.link, value: CryptonetManager.learnURL, range: learnRange)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        attributedString.addAttribute(.paragraphStyle, value: paragraphStyle, range: NSMakeRange(0, fullText.count))

        return attributedString
    }
}

extension PortraitInstructionsViewController: FooterViewDelegate {
    func feedbackTapped() {
        let storyboard = UIStoryboard(name: "FeedbackViewController", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "FeedbackViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
