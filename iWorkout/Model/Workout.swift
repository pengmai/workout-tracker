//
//  Workout.swift
//  iWorkout
//
//  Created by Jacob Peng on 2018-06-10.
//  Copyright © 2018 Jacob Peng. All rights reserved.
//

import Foundation

class Workout: Codable {
    var id: Int
    var user: Int?
    var start: UInt64
    var end: UInt64

    init(id: Int, user: Int, start: UInt64, end: UInt64) {
        self.id = id
        self.user = user
        self.start = start
        self.end = end
    }
}
