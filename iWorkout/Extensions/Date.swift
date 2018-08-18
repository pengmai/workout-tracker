//
//  Date.swift
//  iWorkout
//
//  Created by Jacob Peng on 2018-08-08.
//  Copyright © 2018 Jacob Peng. All rights reserved.
//

import Foundation

extension Date {
    func isSameDayAs(_ other: Date) -> Bool {
        return Calendar.current.compare(self, to: other, toGranularity: .day) == .orderedSame
    }

    func firstDayOfMonth() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: self)

        guard let firstDay = calendar.date(from: components) else {
            fatalError("Couldn't parse date from date \(self)")
        }

        return firstDay
    }

    func getDay() -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: self)

        guard let day = calendar.date(from: components) else {
            fatalError("Couldn't parse date from date \(self)")
        }

        return day
    }
}
