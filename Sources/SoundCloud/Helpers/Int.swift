//
//  Int.swift
//  SC Demo
//
//  Created by Ryan Forsyth on 2023-08-12.
//

import Foundation

public extension Int {
    func dateWithSecondsAdded(to date: Date) -> Date {
        Calendar.current.date(
            byAdding: .second,
            value: self,
            to: date
        )!
    }
}
