//
//  File.swift
//  
//
//  Created by Ryan Forsyth on 2023-08-14.
//

import Foundation

public protocol AuthTokenPersisting {
    func loadAuthTokens() -> OAuthTokenResponse?
    func saveAuthTokens(_ tokens: OAuthTokenResponse) -> Void
    func deleteAuthTokens()
}

public struct UserDefaultsService: AuthTokenPersisting {
    public init() { }
    
    public func loadAuthTokens() -> OAuthTokenResponse? {
        guard
            let data = UserDefaults.standard.object(forKey: OAuthTokenResponse.codingKey) as? Data,
            let tokens = try? JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        else { return nil }
        return tokens
    }
    public func saveAuthTokens(_ tokens: OAuthTokenResponse) {
        let authTokensData = try! JSONEncoder().encode(tokens)
        UserDefaults.standard.set(authTokensData, forKey: OAuthTokenResponse.codingKey)
    }
    public func deleteAuthTokens() {
        UserDefaults.standard.set(nil, forKey: OAuthTokenResponse.codingKey)
    }
}
