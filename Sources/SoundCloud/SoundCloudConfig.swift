//
//  SoundCloudConfig.swift
//  
//
//  Created by Ryan Forsyth on 2023-09-15.
//

///  Object containing properties to configure SoundCloud instance with.
///
///  - Parameter apiURL: Base URL to use for API requests. **Defaults to http://api.soundcloud.com**
///  - Parameter clientID: Client ID to use when authorizing with API and requesting tokens.
///  - Parameter clientSecret: Client secret to use when authorizing with API and requesting tokens.
///  - Parameter redirectURI: URI to use when redirecting from OAuth login page to app. This URI should take the form
public struct SoundCloudConfig {
    public let apiURL: String
    public let clientId: String
    public let clientSecret: String
    public let redirectURI: String
    public init(apiURL: String, clientId: String, clientSecret: String, redirectURI: String) {
        self.apiURL = apiURL
        self.clientId = clientId
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
    }
}
