//
//  TokenResponse.swift
//
//
//  Created by Ryan Forsyth on 2023-10-03.
//

import Foundation

public struct TokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let refreshToken: String
    let scope: String
    let tokenType: String

    var expiryDate: Date? = nil // 💡 Set when persisting object
    
    public init(accessToken: String, expiresIn: Int, refreshToken: String, scope: String, tokenType: String, expiryDate: Date? = nil) {
        self.accessToken = accessToken
        self.expiresIn = expiresIn
        self.refreshToken = refreshToken
        self.scope = scope
        self.tokenType = tokenType
        self.expiryDate = expiryDate
    }
}

internal extension TokenResponse {
    var isExpired: Bool {
        guard let expiryDate else {
            return true
        }
        return expiryDate < Date()
    }
}
