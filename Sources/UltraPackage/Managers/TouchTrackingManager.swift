import Foundation
import UIKit

class TouchTrackingManager {
    static let shared = TouchTrackingManager()
    private var touchEvents: [TouchEvent] = []
    private let fileManager = FileManager.default
    private let filename = "touch_events.json"
    
    private init() {}
    
    func recordTouch(_ touch: UITouch, with event: UIEvent?, isDown: Bool) {
        let touchEvent = TouchEvent(touch: touch, with: event, btnTouch: isDown ? 1 : 0)
        touchEvents.append(touchEvent)
        saveToFile()
    }
    
    private func saveToFile() {
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(touchEvents)
            try data.write(to: fileURL)
        } catch {
            print("Error saving touch events: \(error)")
        }
    }
    
    func clearEvents() {
        touchEvents.removeAll()
        guard let documentsDirectory = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else { return }
        let fileURL = documentsDirectory.appendingPathComponent(filename)
        try? fileManager.removeItem(at: fileURL)
    }
}