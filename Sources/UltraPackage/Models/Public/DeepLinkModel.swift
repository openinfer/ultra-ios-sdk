import Foundation

public class DeeplinkData {
    var sessionToken: String?
    var publicKey: String?
    var selectedBrowser: String?
    var universalLink: String?
    var faceidDuration: String?
    var sessionDuration: String?
    
    public init(sessionToken: String? = nil,
                publicKey: String? = nil,
                selectedBrowser: String? = nil,
                universalLink: String? = nil,
                faceidDuration: String? = nil,
                sessionDuration: String? = nil) {
        self.sessionToken = sessionToken
        self.publicKey = publicKey
        self.selectedBrowser = selectedBrowser
        self.universalLink = universalLink
        self.faceidDuration = faceidDuration
        self.sessionDuration = sessionDuration
    }
}
