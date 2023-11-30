//
//  Config.swift
//  
//
//  Created by Ryan Forsyth on 2023-09-15.
//

///  Object containing properties to configure SoundCloud instance with.
///
///  - Parameter apiURL: Base URL to use for API requests.
///  - Parameter clientID: Client ID to use when authorizing with API and requesting tokens.
///  - Parameter clientSecret: Client secret to use when authorizing with API and requesting tokens.
///  - Parameter redirectURI: URI to use when redirecting from OAuth login page to app. This URI should take the form
extension SoundCloud {
    public struct Config {
        internal let apiURL: String
        internal let clientId: String
        internal let clientSecret: String
        internal let redirectURI: String
        public init(
            apiURL: String = "https://api.soundcloud.com/",
            clientId: String,
            clientSecret: String,
            redirectURI: String
        ) {
            self.apiURL = apiURL
            self.clientId = clientId
            self.clientSecret = clientSecret
            self.redirectURI = redirectURI
        }
    }
}

public extension SoundCloud.Config {
    var authorizationURL: String {
        apiURL
        + "connect"
        + "?client_id=\(clientId)"
        + "&redirect_uri=\(redirectURI)"
        + "&response_type=code"
    }
}
