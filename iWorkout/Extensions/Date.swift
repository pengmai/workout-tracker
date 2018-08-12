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
}
