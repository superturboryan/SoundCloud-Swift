//
//  TokenResponse.swift
//
//
//  Created by Ryan Forsyth on 2023-10-03.
//

import Foundation

internal struct TokenResponse: Codable {
    let accessToken: String
    let expiresIn: Int
    let refreshToken: String
    let scope: String
    let tokenType: String
    
    var expiryDate: Date? = nil // Set when persisting object
}

internal extension TokenResponse {
    var isExpired: Bool {
        expiryDate == nil ? true : expiryDate! < Date()
    }
}
