//
//  Config.swift
//  
//
//  Created by Ryan Forsyth on 2023-09-15.
//

extension SoundCloud {
    
    ///  Properties for configuring SoundCloud API client.
    ///
    ///  These values should be taken from the [SoundCloud developer console](https://soundcloud.com/you/apps).
    ///
    ///  - Parameter clientID: Client ID to use when authorizing with API and requesting tokens.
    ///  - Parameter clientSecret: Client secret to use when authorizing with API and requesting tokens.
    ///  - Parameter redirectURI: URI to use when redirecting from OAuth login page to app (eg: `myapp://oauth`).
    public struct Config: Sendable {
        
        let clientId: String
        let clientSecret: String
        let redirectURI: String
        
        public init(
            clientId: String,
            clientSecret: String,
            redirectURI: String
        ) {
            self.clientId = clientId
            self.clientSecret = clientSecret
            self.redirectURI = redirectURI
        }
    }
}

extension SoundCloud.Config {
    static let apiURL: String = "https://api.soundcloud.com/"
    static let authURL: String = "https://secure.soundcloud.com/"
}
