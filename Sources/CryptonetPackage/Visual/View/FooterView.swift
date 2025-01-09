import UIKit

protocol FooterViewDelegate: AnyObject {
    func languageTapped()
    func feedbackTapped()
}

extension FooterViewDelegate {
    func languageTapped() {}
}

final class FooterView: UIView {
    
    weak var delegate: FooterViewDelegate?
    @IBOutlet weak var privacyLabel: UIButton!
    @IBOutlet weak var termsLabel: UIButton!
    @IBOutlet weak var feedbackLabel: UIButton!
    
    override class func awakeFromNib() {
        super.awakeFromNib()
        print("awakeFromNib")
    }
    
    func setup() {
        self.privacyLabel.setTitle("feedback.privacy".localized, for: .normal)
        self.termsLabel.setTitle("feedback.terms".localized, for: .normal)
        self.feedbackLabel.setTitle("feedback.title".localized, for: .normal)
    }
    
    @IBAction func languageTapped() {
        delegate?.languageTapped()
    }
    
    @IBAction func privacyTapped() {
        if let url = URL(string: "https://privateid.uberverify.com/privacy-policy") {
            UIApplication.shared.open(url)
        }
    }
    
    @IBAction func termsTapped() {
        if let url = URL(string: "https://privateid.uberverify.com/terms") {
            UIApplication.shared.open(url)
        }
    }
    
    @IBAction func feedbackTapped() {
        delegate?.feedbackTapped()
    }
}
