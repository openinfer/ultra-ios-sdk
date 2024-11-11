import UIKit

final class InstructionsViewController: UIViewController {
    
    @IBOutlet weak var footerContainer: UIView!
    @IBOutlet weak var mainImage: UIImageView!
    private let footer: FooterView = .fromNib()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.mainImage.image = UIImage(named: "KV")
        self.navigationItem.setHidesBackButton(true, animated: true)
        footerContainer.addSubview(footer)
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
        let link = CryptonetManager.shared.redirectURL ?? "https://www.google.com/"
        UIApplication.openIfPossible(link: link)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            exit(0)
        }
    }
}
