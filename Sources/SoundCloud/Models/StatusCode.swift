//
//  File.swift
//  
//
//  Created by Ryan Forsyth on 2023-09-07.
//

public extension SoundCloud {
    enum StatusCode: Int {
        case success = 200
        case created = 201
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
        case unknown = 0
        
        public var errorOccurred: Bool {
            switch self {
            case .success, 
                 .created,
                 .found: false
            case .badRequest, 
                 .unauthorized,
                 .forbidden,
                 .notFound,
                 .notAccessible,
                 .unprocessableEntity,
                 .tooManyRequests,
                 .internalServerError,
                 .serviceUnavailable, 
                 .unknown: true
            }
        }
    }
}
