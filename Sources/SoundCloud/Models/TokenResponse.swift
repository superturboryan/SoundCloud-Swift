//
//  TokenResponse.swift
//
//
//  Created by Ryan Forsyth on 2023-10-03.
//

import Foundation

public struct TokenResponse: Codable {
    internal let accessToken: String
    internal let expiresIn: Int
    internal let refreshToken: String
    internal let scope: String
    internal let tokenType: String

    internal var expiryDate: Date? = nil // Set when persisting object
}

internal extension TokenResponse {
    var isExpired: Bool {
        expiryDate == nil ? true : expiryDate! < Date()
    }
}
