import Foundation

public extension String {
    var localized: String {
        return NSLocalizedString(self, bundle: .module, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        let arguments = arguments.compactMap { $0 }
        let localizedString = localized.replacingOccurrences(of: "%s", with: "%@")
        return String(format: localizedString, arguments: arguments)
    }
}
