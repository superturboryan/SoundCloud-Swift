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
    
    var timeStringFromSeconds: String {
        let minutes = String(format: "%02d", ((self % 3600) / 60))
        let seconds = String(format: "%02d", ((self % 3600) % 60))
        var result = minutes + ":" + seconds
        if self >= 3600 {
            let hours = String(format: "%02d", (self / 3600))
            result = hours + ":" + result
        }
        return result
    }
    
    var hoursAndMinutesStringFromSeconds: String {
        let minutesInt = (self % 3600) / 60
        let minutes = String(format: "%02d", minutesInt)
        var result = minutes + "min" + (minutesInt == 1 ? "" : "s")
        if self > 3600 {
            let hours = String(format: "%d", (self / 3600))
            result = hours + "hr " + result
        }
        return result
    }
}
