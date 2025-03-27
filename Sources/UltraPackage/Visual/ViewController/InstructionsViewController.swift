import UIKit

final class InstructionsViewController: BaseViewController, UITextViewDelegate {
    
    @IBOutlet weak var portraitContainer: UIView!
    @IBOutlet weak var portraitTitle: UILabel!
    @IBOutlet weak var portraitTerms: UITextView!
    @IBOutlet weak var portraitAgree: UIButton!
    @IBOutlet weak var portraitBack: UIButton!
    @IBOutlet weak var portraitFooter: UIView!
    @IBOutlet weak var portraitImage: UIImageView!
    
    @IBOutlet weak var landscapeContainer: UIView!
//    @IBOutlet weak var landscapeTitle: UILabel!
//    @IBOutlet weak var landscapeTerms: UITextView!
//    @IBOutlet weak var landscapeAgree: UIButton!
//    @IBOutlet weak var landscapeBack: UIButton!
//    @IBOutlet weak var landscapeFooter: UIView!
//    @IBOutlet weak var landscapeImage: UIImageView!
    
    private let footer: FooterView = .fromNib()
    private let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation
    
    private let tappableTexts = ["verify.identity.privacy.policy".localized, "verify.identity.privacy.terms".localized, "learn_word".localized]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: true)
        
        footer.delegate = self
        
        portraitFooter.addSubview(footer)
//        landscapeFooter.addSubview(footer)
        
        let title = "Take a selfie to register."  // TODO:
        self.portraitTitle.text = title
//        self.landscapeTitle.text = title
        
        let agreeTitle = "privacy.agree.continue.button".localized
        self.portraitAgree.setTitle(agreeTitle, for: .normal)
//        self.landscapeAgree.setTitle(agreeTitle, for: .normal)
        
        
        let backTitle = "noThanks".localized
        self.portraitBack.setTitle(backTitle, for: .normal)
//        self.landscapeBack.setTitle(backTitle, for: .normal)
        
        setupTermsTextView()
        checkOrientationUI()
        
        NotificationCenter.default.addObserver(self, selector: #selector(checkOrientationUI), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let orientation = self.orientation else { return }
        if orientation.isPortrait {
            footer.frame = portraitFooter.bounds
        } else {
//            footer.frame = landscapeFooter.bounds
        }
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
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        UIApplication.shared.open(URL)
        return false // Prevent default behavior
    }
}

private extension InstructionsViewController {

    func setupTermsTextView() {
        let attributedString = makeTermsAttributedText()
        adjustTextView(termsTextView: portraitTerms, with: attributedString)
//        adjustTextView(termsTextView: landscapeTerms, with: attributedString)
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
    
    @objc func checkOrientationUI() {
    
        let isPortrait = orientation?.isPortrait == true
        let isLandscape = orientation?.isLandscape == true

        portraitContainer.isHidden = !isPortrait
        landscapeContainer.isHidden = !isLandscape
    }
}

extension InstructionsViewController: FooterViewDelegate {
    func feedbackTapped() {
        let storyboard = UIStoryboard(name: "CryptonetVisual", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "FeedbackViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
