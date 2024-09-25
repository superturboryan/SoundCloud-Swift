//
//  File.swift
//  
//
//  Created by Ryan Forsyth on 2023-08-14.
//

import Foundation

public extension SoundCloud {
    enum Error: Swift.Error {
        case loggingIn
        case cancelledLogin
        case userNotAuthorized
        case network(StatusCode)
        case decoding
        case invalidURL
        case noInternet
        case refreshingExpiredAuthTokens
        case tooManyRequests
    }
}
