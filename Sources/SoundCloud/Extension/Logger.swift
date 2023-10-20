//
//  Logger.swift
//
//
//  Created by Ryan Forsyth on 2023-10-20.
//

import OSLog

extension Logger {
    
    private static let subsystem = Bundle.module.bundleIdentifier!
    
    static let auth = Logger(subsystem: subsystem, category: "Authentication")
}
