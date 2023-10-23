//
//  Logger.swift
//
//
//  Created by Ryan Forsyth on 2023-10-20.
//

import OSLog

extension Logger {
    
    private static let subsystem = "SoundCloud"
    
    static let auth = Logger(subsystem: subsystem, category: "Authentication")
}
