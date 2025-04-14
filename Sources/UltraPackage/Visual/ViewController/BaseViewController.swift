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
        let link = NetworkManager.shared.redirectURL
        UIApplication.openIfPossible(link: link)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Enable user interaction and multiple touch
        view.isUserInteractionEnabled = true
        view.isMultipleTouchEnabled = true
        
        // Make sure no views are blocking touches
        for subview in view.subviews {
            subview.isUserInteractionEnabled = false
        }
    }
    
    // MARK: - Touch Tracking
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        touches.forEach { touch in
            if touch.view == self.view {
                TouchTrackingManager.shared.recordTouch(touch, with: event, isDown: true)
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        touches.forEach { touch in
            if touch.view == self.view {
                TouchTrackingManager.shared.recordTouch(touch, with: event, isDown: false)
            }
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        touches.forEach { touch in
            if touch.view == self.view {
                TouchTrackingManager.shared.recordTouch(touch, with: event, isDown: false)
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        // We don't track moved events, but override to ensure proper touch handling
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
