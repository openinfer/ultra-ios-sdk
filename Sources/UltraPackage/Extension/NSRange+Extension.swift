import Foundation

extension NSRange {
    func toOptional() -> NSRange? {
        return location == NSNotFound ? nil : self
    }
}
