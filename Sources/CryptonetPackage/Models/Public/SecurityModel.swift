import UIKit

public struct SecurityModel {
    let model: String = UIDevice.current.model
    let sceenBounds: CGRect = UIScreen.main.bounds
    let orientation: UIDeviceOrientation = UIDevice.current.orientation
    let processorCount: Int = ProcessInfo().processorCount
    let battertLevel: Float = UIDevice.current.batteryLevel
    let languageCode: String? = Locale.current.languageCode
}
