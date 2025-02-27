import UIKit

final class InstructionsViewController: BaseViewController {
    
    @IBOutlet weak var mainTitle: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var agreeButton: UIButton!
    @IBOutlet weak var backOptionButton: UIButton!
    @IBOutlet weak var footerContainer: UIView!
    @IBOutlet weak var mainImage: UIImageView!
    private let footer: FooterView = .fromNib()
    
    private let tappableTexts = ["verify.identity.privacy.policy".localized, "verify.identity.privacy.terms".localized, "learn_word".localized]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: true)
        footer.delegate = self
        footerContainer.addSubview(footer)
        setupTermsLabel()
        
        self.mainTitle.text = "Take a selfie to register." // TODO:
        self.agreeButton.setTitle("privacy.agree.continue.button".localized, for: .normal)
        self.backOptionButton.setTitle("noThanks".localized, for: .normal)
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
    
    @objc func handleLabelTap(_ gesture: UITapGestureRecognizer) {
        guard let label = gesture.view as? UILabel, let text = label.attributedText?.string else { return }
        
        let privacyPolicyRange = (text as NSString).range(of: "Privacy Policy")
        let termsOfUseRange = (text as NSString).range(of: "Terms of Use")
        let learnRange = (text as NSString).range(of: "Learn how identity verification works.")
        
        let tapLocation = gesture.location(in: label)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: label.bounds.size)
        
        textContainer.lineFragmentPadding = 0.0
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        let characterIndex = layoutManager.characterIndex(for: tapLocation, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        
        if NSLocationInRange(characterIndex, privacyPolicyRange) {
            runPrivacyPolicy()
        } else if NSLocationInRange(characterIndex, termsOfUseRange) {
            runTermsofUse()
        } else if NSLocationInRange(characterIndex, learnRange) {
            runLearn()
        }
    }
    
    private func setupTermsLabel() {
        let fullText = """
        By clicking the 'Agree and continue' button below, you acknowledge that you are over eighteen (18) years of age, have read the Private Identity Privacy Policy and Terms of Use and understand how your personal data will be processed in connection with your use of this Identity Verification Service.
        
        Learn how identity verification works.
        """
        
        let attributedString = NSMutableAttributedString(string: fullText)
        
        let privacyPolicyRange = (fullText as NSString).range(of: "Privacy Policy")
        let termsOfUseRange = (fullText as NSString).range(of: "Terms of Use")
        let learnRange = (fullText as NSString).range(of: "Learn how identity verification works.")
        
        // Add underline and color
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: privacyPolicyRange)
        attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: privacyPolicyRange)
        
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: termsOfUseRange)
        attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: termsOfUseRange)
        
        attributedString.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: learnRange)
        attributedString.addAttribute(.foregroundColor, value: UIColor.black, range: learnRange)
        
        titleLabel.attributedText = attributedString
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleLabelTap(_:)))
        titleLabel.addGestureRecognizer(tapGesture)
    }
}

extension InstructionsViewController: FooterViewDelegate {
    func feedbackTapped() {
        let storyboard = UIStoryboard(name: "CryptonetVisual", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "FeedbackViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
