import UIKit
import ProgressHUD

class BaseViewController: UIViewController {
    
    func setUpCloseButton() {
        let buttonClose = UIBarButtonItem(image: UIImage(systemName: "xmark")?.withTintColor(.black), style: .plain, target: self, action: #selector(reset))
        navigationItem.rightBarButtonItems = [buttonClose]
    }
    
    @objc func reset() {
//        CryptonetManager.shared.isLoggedIn = false
        ProgressHUD.dismiss()
//        FlowManager.shared.reset()
        navigationController?.popToRootViewController(animated: true)
    }
    
    func openRedirectURL() {
        var link = CryptonetManager.shared.redirectURL ?? NetworkManager.shared.redirectURL
        
        if link.contains(CryptonetManager.defaultProject),
           let token = CryptonetManager.shared.sessionToken {
            link = link + "?sessionId=\(token)"
        }

        CryptonetManager.shared.resetSession()
        UIApplication.openIfPossible(link: link)
        self.reset()
    }
}

extension BaseViewController {
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
    
    // Function to find character index at tap location
    func characterIndexAtPoint(_ point: CGPoint, in label: UILabel) -> Int? {
        guard let attributedText = label.attributedText else { return nil }
        
        let textStorage = NSTextStorage(attributedString: attributedText)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: label.bounds.size)
        textContainer.lineFragmentPadding = 0.0
        
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        
        let glyphIndex = layoutManager.glyphIndex(for: point, in: textContainer)
        
        return glyphIndex
    }
}
