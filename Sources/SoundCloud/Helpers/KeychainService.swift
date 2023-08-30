//
//  File.swift
//  
//
//  Created by Ryan Forsyth on 2023-08-30.
//

import Foundation
import KeychainSwift

public struct KeychainService: AuthTokenPersisting {
    private let kc = KeychainSwift()
    
    public init() {}
    
    public func loadAuthTokens() -> OAuthTokenResponse? {
        guard
            let tokenData = kc.getData(OAuthTokenResponse.codingKey),
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
        kc.set(authTokensData, forKey: OAuthTokenResponse.codingKey)
    }
    
    public func deleteAuthTokens() {
        kc.delete(OAuthTokenResponse.codingKey)
    }
}
