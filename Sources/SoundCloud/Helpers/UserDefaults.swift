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
            let tokenData = UserDefaults.standard.object(forKey: OAuthTokenResponse.codingKey) as? Data,
            let tokens = try? JSONDecoder().decode(OAuthTokenResponse.self, from: tokenData)
        else {
            return nil
        }
        return tokens
    }
    public func saveAuthTokens(_ tokens: OAuthTokenResponse) {
        var tokensWithDateSet = tokens
        tokensWithDateSet.expiryDate = tokens.expiresIn.dateWithSecondsAdded(to: Date())
        let authTokensData = try! JSONEncoder().encode(tokensWithDateSet)
        UserDefaults.standard.set(authTokensData, forKey: OAuthTokenResponse.codingKey)
        UserDefaults.standard.synchronize()
    }
    public func deleteAuthTokens() {
        UserDefaults.standard.set(nil, forKey: OAuthTokenResponse.codingKey)
        UserDefaults.standard.set(nil, forKey: "expiry")
    }
}
