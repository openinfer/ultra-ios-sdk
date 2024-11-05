import UIKit

public class CryptonetVisual: UIView, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var greetings: UILabel!
    
    public func runCamera(viewController: UIViewController) {
        print("Test")
        let cameraVc = UIImagePickerController()
        cameraVc.sourceType = UIImagePickerController.SourceType.camera
        cameraVc.delegate = self
        viewController.present(cameraVc, animated: true, completion: nil)
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            //save image
            //display image
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
}
