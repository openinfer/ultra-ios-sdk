import UIKit

final class UserConsentViewController: BaseViewController {
    
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var termsButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var footerContainer: UIView!
    @IBOutlet weak var mainImage: UIImageView!
    @IBOutlet weak var termsLable: UILabel!
    @IBOutlet weak var acceptLabel: UILabel!
    @IBOutlet weak var mainTitle: UILabel!
    
    private let footer: FooterView = .fromNib()
    private let tappableTexts = ["Privacy Policy", "Terms of Use"]
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        footer.delegate = self
        footerContainer.addSubview(footer)
        
        mainTitle.text = "user.consent".localized
        setUpCloseButton()
        
        let text = "I have read and accepted the Private Identity LLC Terms of Use and Privacy Policy, CentralAMS Terms of Use and Privacy Policy, and the IDEMIA Terms of Use and Privacy Policy."
        
        let attributedString = NSMutableAttributedString(string: text)
        
        // Apply tap attributes to each occurrence of "Privacy Policy" and "Terms of Use"
        for tappable in tappableTexts {
            let ranges = findRanges(of: tappable, in: text)
            for range in ranges {
                attributedString.addAttributes([
                    .foregroundColor: UIColor.link,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ], range: range)
            }
        }
        
        termsLable.attributedText = attributedString
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped(_:)))
        termsLable.addGestureRecognizer(tapGesture)
        
        let acceptGesture = UITapGestureRecognizer(target: self, action: #selector(acceptTapped))
        acceptGesture.numberOfTapsRequired = 1
        self.acceptLabel.addGestureRecognizer(acceptGesture)

        self.continueButton.setTitle("continue.button".localized, for: .normal)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateContinueState(isOn: termsButton.isSelected)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        scrollView.delegate = self
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        footer.frame = footerContainer.bounds
    }
    
    @IBAction func doneTapped(sender: UIButton) {
        let storyboard = UIStoryboard(name: "CryptonetVisual", bundle: Bundle.module)
        if let vc = storyboard.instantiateViewController(withIdentifier: "FaceInstructionViewController") as? FaceInstructionViewController {
            self.navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    @IBAction func termsTapped(sender: UIButton) {
        termsButton.isSelected = !termsButton.isSelected
        updateContinueState(isOn: sender.isSelected)
    }
    
    @objc func acceptTapped() {
        termsButton.isSelected = !termsButton.isSelected
        updateContinueState(isOn: termsButton.isSelected)
    }
    
    private func updateContinueState(isOn: Bool) {
        continueButton.isUserInteractionEnabled = isOn
        continueButton.alpha = isOn ? 1.0 : 0.6
    }
    
    @objc func labelTapped(_ gesture: UITapGestureRecognizer) {
        guard let attributedText = termsLable.attributedText else { return }
        
        let tapLocation = gesture.location(in: termsLable)
        
        if let tappedIndex = characterIndexAtPoint(tapLocation, in: termsLable) {
           let tappedData = getTappedTextAtIndex(tappedIndex, in: attributedText.string)

            if tappedData == "verify.identity.privacy.policy".localized {
                runPrivacyPolicy()
            } else if tappedData == "verify.identity.privacy.terms".localized {
                runTermsofUse()
            }
        }
    }
    
    private func getTappedTextAtIndex(_ index: Int, in text: String) -> String {
        for tappable in tappableTexts {
            let ranges = findRanges(of: tappable, in: text)
            for range in ranges {
                if NSLocationInRange(index, range) {
                    return tappable
                }
            }
        }
        return ""
    }
}

extension UserConsentViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if (scrollView.contentOffset.y + 1) >= (scrollView.contentSize.height - scrollView.frame.size.height) {
            termsButton.isSelected = true
            updateContinueState(isOn: true)
         }
    }
}

extension UserConsentViewController: FooterViewDelegate {
    func feedbackTapped() {
        let storyboard = UIStoryboard(name: "CryptonetVisual", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "FeedbackViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
