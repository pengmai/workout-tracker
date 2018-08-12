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
    var start: Date
    var end: Date

    var description: String {
        return """
            Workout:
            {
            \tid: \(id),
            \tstart: \(Workout.formatter.string(from: start)),
            \tend: \(Workout.formatter.string(from: end))
            }
            """
    }

    init(id: Int, user: Int, start: Date, end: Date) {
        self.id = id
        self.user = user
        self.start = start
        self.end = end
    }
}
