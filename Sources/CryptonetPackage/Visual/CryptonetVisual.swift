import UIKit

public class CryptonetVisual: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var greetings: UILabel!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        runCamera()
    }
    
    public func runCamera() {
        print("Test")
        let cameraVc = UIImagePickerController()
        cameraVc.sourceType = UIImagePickerController.SourceType.camera
        cameraVc.delegate = self
        self.present(cameraVc, animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            //save image
            //display image
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
}
