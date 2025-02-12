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

    private let tappableTexts = ["Privacy Policy", "Terms of Use", "Learn"]

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.setHidesBackButton(true, animated: true)
        footer.delegate = self
        footerContainer.addSubview(footer)

        let titleText = "By clicking the 'Agree and continue' button below, you acknowledge that you are over eighteen (18) years of age, have read the Private Identity Privacy Policy and Terms of Use and understand how your personal data will be processed in connection with your use of this Identity Verification Service."
        
        let subtitleText = "Learn how identity verification works."

        let attributedTitleString = NSMutableAttributedString(string: titleText)
        let attributedSubtitleString = NSMutableAttributedString(string: subtitleText)

        for tappable in tappableTexts {
            let ranges = findRanges(of: tappable, in: titleText)
            for range in ranges {
                attributedTitleString.addAttributes([
                    .foregroundColor: UIColor.black,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ], range: range)
            }
        }

        for tappable in tappableTexts {
            let ranges = findRanges(of: tappable, in: subtitleText)
            for range in ranges {
                attributedSubtitleString.addAttributes([
                    .foregroundColor: UIColor.black,
                    .underlineStyle: NSUnderlineStyle.single.rawValue
                ], range: range)
            }
        }

        self.titleLabel.attributedText = attributedTitleString
        self.subtitleLabel.attributedText = attributedSubtitleString

        let tapTitleGesture = UITapGestureRecognizer(target: self, action: #selector(titleTapped(_:)))
        titleLabel.addGestureRecognizer(tapTitleGesture)
        titleLabel.isUserInteractionEnabled = true

        let tapSubtitleGesture = UITapGestureRecognizer(target: self, action: #selector(subtitleTapped(_:)))
        subtitleLabel.addGestureRecognizer(tapSubtitleGesture)
        subtitleLabel.isUserInteractionEnabled = true

        self.mainTitle.text = "Take a selfie to register."
        self.agreeButton.setTitle("privacy.agree.continue.button".localized, for: .normal)
        self.backOptionButton.setTitle("noThanks".localized, for: .normal)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        footer.frame = footerContainer.bounds
    }

    // MARK: - Actions

    @objc func titleTapped(_ gesture: UITapGestureRecognizer) {
        handleTap(gesture, in: titleLabel)
    }

    @objc func subtitleTapped(_ gesture: UITapGestureRecognizer) {
        handleTap(gesture, in: subtitleLabel)
    }

    private func handleTap(_ gesture: UITapGestureRecognizer, in label: UILabel) {
        guard let attributedText = label.attributedText else { return }
        
        let tapLocation = gesture.location(in: label)

        if let tappedIndex = characterIndexAtPoint(tapLocation, in: label) {
            let tappedData = getTappedTextAtIndex(tappedIndex, in: attributedText.string)

            switch tappedData {
            case "Privacy Policy":
                runPrivacyPolicy()
            case "Terms of Use":
                runTermsofUse()
            case "Learn":
                runLearn()
            default:
                break
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

extension InstructionsViewController {
    func findRanges(of searchText: String, in fullText: String) -> [NSRange] {
        let nsText = fullText as NSString
        var ranges: [NSRange] = []
        var searchRange = NSRange(location: 0, length: nsText.length)
        
        while let foundRange = nsText.range(of: searchText, options: [], range: searchRange).toOptional(), foundRange.location != NSNotFound {
            ranges.append(foundRange)
            searchRange = NSRange(location: foundRange.upperBound, length: nsText.length - foundRange.upperBound)
        }
        return ranges
    }

    func characterIndexAtPoint(_ point: CGPoint, in label: UILabel) -> Int? {
        guard let attributedText = label.attributedText else { return nil }
        
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: label.bounds.size)
        textContainer.lineFragmentPadding = 0.0
        textContainer.maximumNumberOfLines = label.numberOfLines
        textContainer.lineBreakMode = label.lineBreakMode

        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        let textRect = layoutManager.usedRect(for: textContainer)

        // Adjust tap location based on text alignment
        var adjustedPoint = point
        let horizontalOffset: CGFloat
        switch label.textAlignment {
        case .center:
            horizontalOffset = (label.bounds.width - textRect.width) / 2.0
        case .right:
            horizontalOffset = label.bounds.width - textRect.width
        default:
            horizontalOffset = 0
        }
        adjustedPoint.x -= horizontalOffset

        // Ensure the tap is inside the actual text bounds
        guard textRect.contains(CGPoint(x: adjustedPoint.x, y: point.y)) else { return nil }

        // Convert to glyph index
        let glyphIndex = layoutManager.glyphIndex(for: adjustedPoint, in: textContainer)
        
        // Convert glyph index to character index
        let characterIndex = layoutManager.characterIndexForGlyph(at: glyphIndex)

        return characterIndex < attributedText.length ? characterIndex : nil
    }

    func runPrivacyPolicy() {
        if let url = URL(string: CryptonetManager.privacyURL) {
            UIApplication.shared.open(url)
        }
    }

    func runTermsofUse() {
        if let url = URL(string: CryptonetManager.termsURL) {
            UIApplication.shared.open(url)
        }
    }

    func runLearn() {
        if let url = URL(string: CryptonetManager.learnURL) {
            UIApplication.shared.open(url)
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
