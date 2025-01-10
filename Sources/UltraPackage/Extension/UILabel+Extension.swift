import UIKit

extension UILabel {
    func underlineWords(words: [String]) {
        guard let textString = text else {
            return
        }
        let attributedText = NSMutableAttributedString(string: text ?? "")
        for word in words {
            let rangeToUnderline = (textString as NSString).range(of: word)
            attributedText.addAttribute(NSAttributedString.Key.underlineStyle,
                                        value: NSUnderlineStyle.single.rawValue,
                                        range: rangeToUnderline)
            attributedText.addAttribute(NSAttributedString.Key.foregroundColor,
                                        value: UIColor.systemBlue,
                                        range: rangeToUnderline)
        }
        isUserInteractionEnabled = true
        self.attributedText = attributedText
    }
}
