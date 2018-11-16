//
//  Extensions.swift
//  iWorkoutTests
//
//  Created by Jacob Peng on 2018-08-18.
//  Copyright © 2018 Jacob Peng. All rights reserved.
//

import XCTest

extension UIViewController {
    func preloadView() {
        XCTAssertNotNil(view)
    }
}
