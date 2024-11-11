import Foundation

final class FlowManager {
    
    enum FlowType {
        case signIn
        case enroll
        case matchFace
    }
    
    static let shared = FlowManager()
    
    private init() { }
    
    var current: FlowType = .signIn
}
