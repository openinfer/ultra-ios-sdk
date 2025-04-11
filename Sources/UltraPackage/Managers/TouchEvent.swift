import UIKit

struct TouchEvent: Codable {
    let timestamp: TimeInterval
    let x: CGFloat
    let y: CGFloat
    let btnTouch: Int // 1 for touch down, 0 for touch up
    let touchMajor: CGFloat
    let touchMinor: CGFloat
    let trackingId: String
    let pressure: CGFloat
    let finger: Int
    
    init(touch: UITouch, with event: UIEvent?, btnTouch: Int) {
        self.timestamp = event?.timestamp ?? Date().timeIntervalSince1970
        let location = touch.location(in: nil)
        self.x = location.x
        self.y = location.y
        self.btnTouch = btnTouch
        self.touchMajor = touch.majorRadius
        self.touchMinor = touch.majorRadius // Using majorRadius as iOS doesn't provide minorRadius
        self.trackingId = String(describing: touch)
        self.pressure = touch.force / touch.maximumPossibleForce
        self.finger = 0 // Default to 0 as iOS doesn't provide direct finger index
    }
}
