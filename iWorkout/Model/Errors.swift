//
//  Errors.swift
//  iWorkout
//
//  Created by Jacob Peng on 2018-06-10.
//  Copyright © 2018 Jacob Peng. All rights reserved.
//

import Foundation

enum WorkoutError: Error {
    case networkError(message: String)
    case urlError
}
