import UIKit

public class SecurityModel {
    let model: String
    let sceenBounds: CGRect
    let orientation: UIDeviceOrientation
    let processorCount: Int
    let battertLevel: Float
    let languageCode: String?
    
    public init() {
        self.model = UIDevice.current.model
        self.sceenBounds = UIScreen.main.bounds
        self.orientation = UIDevice.current.orientation
        self.processorCount = ProcessInfo().processorCount
        self.battertLevel = UIDevice.current.batteryLevel
        self.languageCode = Locale.current.languageCode
    }
}
