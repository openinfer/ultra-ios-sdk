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
        
        let titleText = "I have read and accepted the Private Identity LLC Terms of Use and Privacy Policy, CentralAMS Terms of Use and Privacy Policy, and the IDEMIA Terms of Use and Privacy Policy."

        let attributedTitleString = NSMutableAttributedString(string: titleText)

        for tappable in tappableTexts {
            let ranges = findRanges(of: tappable, in: titleText)
            for range in ranges {
                attributedTitleString.addAttributes([
                    .foregroundColor: UIColor.black,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ], range: range)
            }
        }

        self.titleLabel.attributedText = attributedTitleString

        let tapTitleGesture = UITapGestureRecognizer(target: self, action: #selector(titleTapped(_:)))
        titleLabel.addGestureRecognizer(tapTitleGesture)

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
        let identifier = "UserConsentViewController"
        let storyboard = UIStoryboard(name: "CryptonetVisual", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: identifier)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
    @IBAction func backTapped() {
        self.navigationController?.popToRootViewController(animated: true)
    }
    
    @objc func titleTapped(_ gesture: UITapGestureRecognizer) {
        guard let attributedText = titleLabel.attributedText else { return }
        
        let tapLocation = gesture.location(in: titleLabel)
        
        if let tappedIndex = characterIndexAtPoint(tapLocation, in: titleLabel) {
           let tappedData = getTappedTextAtIndex(tappedIndex, in: attributedText.string)

            if tappedData == "verify.identity.privacy.policy".localized {
                runPrivacyPolicy()
            } else if tappedData == "verify.identity.privacy.terms".localized {
                runTermsofUse()
            } else if tappedData == "learn_word".localized {
                runLearn()
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

extension InstructionsViewController: FooterViewDelegate {
    func feedbackTapped() {
        let storyboard = UIStoryboard(name: "CryptonetVisual", bundle: Bundle.module)
        let vc = storyboard.instantiateViewController(withIdentifier: "FeedbackViewController")
        self.navigationController?.pushViewController(vc, animated: true)
    }
}
