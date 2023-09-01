//
//  File.swift
//  
//
//  Created by Ryan Forsyth on 2023-08-30.
//


public protocol AuthTokenPersisting {
    var authTokens: OAuthTokenResponse? { get }
    func save(_ tokens: OAuthTokenResponse) -> Void
    func delete()
}
