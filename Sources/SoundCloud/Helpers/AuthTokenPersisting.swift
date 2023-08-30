//
//  File.swift
//  
//
//  Created by Ryan Forsyth on 2023-08-30.
//


public protocol AuthTokenPersisting {
    func loadAuthTokens() -> OAuthTokenResponse?
    func saveAuthTokens(_ tokens: OAuthTokenResponse) -> Void
    func deleteAuthTokens()
}
