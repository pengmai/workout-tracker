//
//  ViewController.swift
//  iWorkout
//
//  Created by Jacob Peng on 2018-04-18.
//  Copyright © 2018 Jacob Peng. All rights reserved.
//

import UIKit
import JTAppleCalendar
import os

class HomeViewController: UIViewController {
    // MARK: - Properties
    @IBOutlet weak var calendarHeader: UILabel!
    @IBOutlet weak var calendarView: JTAppleCalendarView!
    @IBOutlet weak var headerLabel: UINavigationItem!

    var resp: LoginResponse!
    var workouts = [Date: [Workout]]()
    var user: User!

    let formatter = DateFormatter()
    let outsideMonthColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
    let monthColor = UIColor.black

    override func viewDidLoad() {
        super.viewDidLoad()
        self.workouts = Dictionary(grouping: resp.workouts, by: { $0.end.getDay() })
        self.user = resp.user
        self.headerLabel.title = "\(resp.user.name)'s Workouts"
        self.calendarView.reloadData()

        // Do any additional setup after loading the view, typically from a nib.
        setupCalendarView()
        navigationController?.isNavigationBarHidden = false
    }

    private func setupCalendarView() {
        calendarView.visibleDates(handleCalendarHeader)
        calendarView.scrollToDate(Date())
    }

    private func handleCalendarHeader(visibleDates: DateSegmentInfo) {
        guard let date = visibleDates.monthDates.first?.date else { return }
        formatter.dateFormat = "MMMM yyyy"
        calendarHeader.text = formatter.string(from: date)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    // MARK: - Actions
    @IBAction func logOutButtonPressed(_ sender: UIBarButtonItem) {
        let confirmationAlert = UIAlertController(title: "Are you sure you want to log out?", message: nil, preferredStyle: .alert)
        confirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        confirmationAlert.addAction(UIAlertAction(title: "Log out", style: .destructive, handler: { (_) in
            self.performSegue(withIdentifier: "returnToLoginPage", sender: sender)
        }))

        present(confirmationAlert, animated: true, completion: nil)
    }


    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
            case "AddWorkout":
                guard let destination = segue.destination as? UINavigationController,
                    let target = destination.topViewController as? WorkoutViewController else {
                    fatalError("Unable to retrieve WorkoutViewController for segue AddWorkout")
                }

                target.addWorkoutDelegate = self
                target.shouldUnwindToTable = false
                target.user = user.id
            case "ListWorkouts":
                guard let destination = segue.destination as? WorkoutTableViewController else {
                    fatalError("Destination was not a WorkoutTableViewController for segue ListWorkouts")
                }
                guard let workouts = sender as? [Workout] else {
                    fatalError("Did not receive list of workouts")
                }

                destination.workouts = workouts
                destination.user = user.id
                destination.updateWorkoutDelegate = self
                destination.deleteWorkoutDelegate = self
            case "ViewWorkout":
                guard let destination = segue.destination as? WorkoutViewController else {
                    fatalError("Destination was not a WorkoutViewController for segue ListWorkouts")
                }
                guard let workout = sender as? Workout else {
                    fatalError("Did not receive workout")
                }

                destination.updateWorkoutDelegate = self
                destination.deleteWorkoutDelegate = self
                destination.shouldUnwindToTable = false
                destination.workout = workout
                destination.user = user.id
            case "ViewCharts":
                guard let destination = segue.destination as? ChartsViewController else {
                    fatalError("Destination was not a ChartsViewController for segue ViewCharts")
                }

                destination.workouts = workouts
            case "returnToLoginPage":
                break
            default:
                fatalError("Unexpected segue identifier: \(segue.identifier ?? "nil")")
        }
    }

    @IBAction func returnToViewController(segue: UIStoryboardSegue) {
    }
}

// MARK: - Add Workout Delegate
protocol AddWorkoutDelegate: class {
    func add(workout: Workout)
}

extension HomeViewController: AddWorkoutDelegate {
    func add(workout: Workout) {
        let day = workout.end.getDay()
        if var workoutsForDay = workouts[day] {
            workoutsForDay.append(workout)
            workoutsForDay.sort { $0.end < $1.end }
            workouts[day] = workoutsForDay
        } else {
            workouts[day] = [workout]
        }
        calendarView.reloadData()
        calendarView.scrollToDate(workout.end)
    }
}

// MARK: - Update Workout Delegate
protocol UpdateWorkoutDelegate: class {
    func update(workout: Workout)
}

extension HomeViewController: UpdateWorkoutDelegate {
    func update(workout: Workout) {
        // Flatten the dictionary of workouts.
        var workoutList = workouts.reduce([]) { $0 + $1.value }
        guard let i = workoutList.index(where: { $0.id == workout.id }) else {
            fatalError("Tried to update a workout that wasn't in the list of workouts")
        }

        let previous = workoutList[i]
        workoutList[i] = workout
        workoutList.sort { $0.end < $1.end }
        workouts = Dictionary(grouping: workoutList, by: { $0.end.getDay() })
        calendarView.reloadDates([previous.end, workout.end])
    }
}

// MARK: - Delete Workout Delegate
protocol DeleteWorkoutDelegate: class {
    func delete(workout: Workout)
    func getNumberOfRemainingWorkouts() -> Int
}

extension HomeViewController: DeleteWorkoutDelegate {
    func delete(workout: Workout) {
        var workoutList = workouts.reduce([], { $0 + $1.value })
        guard let i = workoutList.index(where: { $0.id == workout.id }) else {
            fatalError("Tried to remove a workout that wasn't in the list of workouts")
        }

        workoutList.remove(at: i)
        workouts = Dictionary(grouping: workoutList, by: { $0.end.getDay() })
        calendarView.reloadDates([workout.end])
    }

    func getNumberOfRemainingWorkouts() -> Int {
        fatalError("Not implemented in the main view controller")
    }
}

// MARK: - Calendar settings
extension HomeViewController: JTAppleCalendarViewDelegate, JTAppleCalendarViewDataSource {
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        var start = Date()
        if let first = workouts.reduce([], { $0 + $1.value }).sorted(by: { $0.end < $1.end }).first {
            start = first.end
        }
        let now = Date()

        return ConfigurationParameters(
            startDate: start,
            endDate: now,
            generateOutDates: .tillEndOfRow
        )
    }

    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        let calendarCell = cell as! CalendarCell
        configureVisibleCell(cell: calendarCell, cellState: cellState, date: date)
    }

    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        if let thisDaysWorkouts = workouts[date.getDay()] {
            if thisDaysWorkouts.count > 1 {
                performSegue(withIdentifier: "ListWorkouts", sender: thisDaysWorkouts)
            } else if let first = thisDaysWorkouts.first {
                performSegue(withIdentifier: "ViewWorkout", sender: first)
            }
        }
    }

    func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
        let cell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "CalendarCell", for: indexPath) as! CalendarCell
        configureVisibleCell(cell: cell, cellState: cellState, date: date)
        return cell
    }

    func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
        handleCalendarHeader(visibleDates: visibleDates)
    }

    func configureVisibleCell(cell: CalendarCell, cellState: CellState, date: Date) {
        cell.dateLabel.text = cellState.text
        cell.withWorkout.textColor = .white

        if cellState.dateBelongsTo == .thisMonth {
            if date.isSameDayAs(Date()) {
                cell.dateLabel.textColor = .red
            } else {
                cell.dateLabel.textColor = monthColor
            }
        } else {
            cell.dateLabel.textColor = outsideMonthColor
        }

        if let workoutsForDay = workouts[date.getDay()] {
            if workoutsForDay.count == 1 {
                cell.withWorkout.textColor = .blue
            } else {
                cell.withWorkout.textColor = .green
            }
        }
    }
}
