//
//  Workout.swift
//  iWorkout
//
//  Created by Jacob Peng on 2018-06-10.
//  Copyright © 2018 Jacob Peng. All rights reserved.
//

import Foundation

class Workout: Codable, CustomStringConvertible {
    static var formatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.timeZone = Calendar.current.timeZone
        formatter.locale = Calendar.current.locale
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter
    }

    var id: Int
    var user: Int?
    var start: UInt64
    var end: UInt64

    var description: String {
        let startDate = Date(timeIntervalSince1970: TimeInterval(start))
        let endDate = Date(timeIntervalSince1970: TimeInterval(end))
        return """
            Workout:
            {
            \tid: \(id),
            \tstart: \(Workout.formatter.string(from: startDate)),
            \tend: \(Workout.formatter.string(from: endDate))
            }
            """
    }

    init(id: Int, user: Int, start: UInt64, end: UInt64) {
        self.id = id
        self.user = user
        self.start = start
        self.end = end
    }
}
