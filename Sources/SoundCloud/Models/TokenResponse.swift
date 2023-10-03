//
//  TokenResponse.swift
//
//
//  Created by Ryan Forsyth on 2023-10-03.
//

import Foundation

public struct TokenResponse: Codable {
    public let accessToken: String
    public let expiresIn: Int
    public let refreshToken: String
    public let scope: String
    public let tokenType: String
    
    internal var expiryDate: Date? = nil // Set when persisting object
}

extension TokenResponse {
    public var isExpired: Bool {
        expiryDate == nil ? true : expiryDate! < Date()
    }
    public static var empty: Self {
        TokenResponse(
            accessToken: "",
            expiresIn: 0,
            refreshToken: "",
            scope: "",
            tokenType: ""
        )
    }
}
