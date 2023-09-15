//
//  File.swift
//  
//
//  Created by Ryan Forsyth on 2023-08-14.
//

import Foundation

public extension SoundCloud {
    enum Error: LocalizedError {
        case trackDownloadNotInProgress
        case userNotAuthorized
        case network(StatusCode)
        case decoding
        case noInternet
        case refreshingExpiredAuthTokens
        case removingDownloadedTrack
    }
}
