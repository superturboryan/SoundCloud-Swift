//
//  File.swift
//  
//
//  Created by Ryan Forsyth on 2023-09-07.
//

import Foundation

public extension SoundCloud {
    enum StatusCode: Int {
        case success = 200
        case found = 302
        case badRequest = 400
        case unauthorized = 401
        case forbidden = 403
        case notFound = 404
        case notAccessible = 406
        case unprocessableEntity = 422
        case tooManyRequests = 429
        case internalServerError = 500
        case serviceUnavailable = 503
        
        var errorOccurred: Bool {
            switch self {
            case .success, .found:
                return false
            default:
                return true
            }
        }
    }
}