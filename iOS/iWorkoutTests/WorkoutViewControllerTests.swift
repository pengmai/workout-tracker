//
//  iWorkoutTests.swift
//  iWorkoutTests
//
//  Created by Jacob Peng on 2018-04-18.
//  Copyright © 2018 Jacob Peng. All rights reserved.
//

import XCTest
@testable import iWorkout

class WorkoutViewControllerTests: XCTestCase {
    var workoutViewController: WorkoutViewController!

    override func setUp() {
        super.setUp()
        let storyboard = UIStoryboard(name: "Main", bundle: Bundle.main)
        workoutViewController = (storyboard.instantiateViewController(withIdentifier: "WorkoutViewController") as! WorkoutViewController)
        workoutViewController.user = 1
    }

    override func tearDown() {
        super.tearDown()
    }

    // MARK: - Date Picker tests
    func testSetDatesInFuture() {
        // Arrange.
        workoutViewController.preloadView()
        let start = Date() + TimeInterval(120)
        let end = start + TimeInterval(120)

        // Act.
        setDates(start: start, end: end)

        // Assert.
        XCTAssertEqual(workoutViewController.startTimePicker.date, start)
        XCTAssertEqual(workoutViewController.endTimePicker.date, end)
    }

    func testSetDatesInPast() {
        // Arrange.
        workoutViewController.preloadView()
        let start = Date() - TimeInterval(260)
        let end = start + TimeInterval(60)

        // Act.
        setDates(start: start, end: end)

        // Assert.
        XCTAssertEqual(workoutViewController.startTimePicker.date, start)
        XCTAssertEqual(workoutViewController.endTimePicker.date, end)
    }

    func testPreventEndDateBeforeStartDate() {
        // Arrange.
        workoutViewController.preloadView()
        let now = Date()

        // Act.
        setDates(start: now, end: now)

        // Assert.
        XCTAssertLessThan(workoutViewController.startTimePicker.date, workoutViewController.endTimePicker.date)
    }

//    func testExample() {
//        workoutViewController.workout = Workout(id: 1, user: 1, start: Date() - TimeInterval(60), end: Date())
//        workoutViewController.preloadView()
//        print(workoutViewController.navigationBar.title ?? "nil")
//    }

    private func setDates(start: Date, end: Date) {
        let startPicker = workoutViewController.startTimePicker!
        let endPicker = workoutViewController.endTimePicker!

        startPicker.date = start
        workoutViewController.startDateChanged(startPicker)
        endPicker.date = end
        workoutViewController.endDateChanged(endPicker)
    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }
}
