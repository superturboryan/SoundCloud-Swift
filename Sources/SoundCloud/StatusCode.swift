//
//  File.swift
//  
//
//  Created by Ryan Forsyth on 2023-09-07.
//

import Foundation

public extension SC {
    enum StatusCode: Int {
        case success = 200
        case found = 302
        case badRequest = 400
        case unauthorized = 401
        case notFound = 404
        case internalServerError = 500
        
        var errorOccurred: Bool {
            switch self {
            case .success, .found:
                return false
            case .badRequest, .unauthorized, .notFound, .internalServerError:
                return true
            }
        }
    }
}
