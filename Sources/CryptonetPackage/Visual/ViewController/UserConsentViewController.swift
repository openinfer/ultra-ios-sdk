import UIKit

final class UserConsentViewController: UIViewController {
    
    @IBOutlet weak var mainTitle: UILabel!
    @IBOutlet weak var termsTitle: UILabel!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var termsButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var footerContainer: UIView!
    @IBOutlet weak var mainImage: UIImageView!

    
    private let footer: FooterView = .fromNib()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        footer.delegate = self
        footerContainer.addSubview(footer)
        
        mainTitle.text = "user.consent".localized
        termsTitle.text = "agree.terms.policy".localized
        continueButton.setTitle("continue.button".localized, for: .normal)
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
    
    private func updateContinueState(isOn: Bool) {
        continueButton.isUserInteractionEnabled = isOn
        continueButton.alpha = isOn ? 1.0 : 0.6
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
