//
//  File.swift
//  
//
//  Created by Ryan Forsyth on 2023-08-14.
//

import Foundation

public extension SoundCloud {
    enum Error: LocalizedError {
        case failedLoadingPersistedTokens
        case trackDownloadNotInProgress
        case userNotAuthorized
        case networkError(StatusCode)
    }
}

