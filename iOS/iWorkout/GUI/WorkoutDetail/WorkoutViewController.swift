//
//  WorkoutViewController.swift
//  iWorkout
//
//  Created by Jacob Peng on 2018-04-18.
//  Copyright © 2018 Jacob Peng. All rights reserved.
//

import UIKit
import os

class WorkoutViewController: UIViewController {
    // MARK: - Constants
    let minute: TimeInterval = 60

    // MARK: - Properties
    @IBOutlet weak var segmentedControl: UISegmentedControl!
    @IBOutlet weak var stopWatchLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var resetButton: UIButton!

    @IBOutlet weak var startTimePicker: UIDatePicker!
    @IBOutlet weak var endTimePicker: UIDatePicker!
    @IBOutlet weak var navigationBar: UINavigationItem!
    @IBOutlet weak var saveButton: UIBarButtonItem!
    weak var addWorkoutDelegate: AddWorkoutDelegate?
    weak var updateWorkoutDelegate: UpdateWorkoutDelegate?
    weak var deleteWorkoutDelegate: DeleteWorkoutDelegate?

    var running = false
    var timer = Timer()
    var user: Int!
    var workout: Workout?
    var numberOfSeconds: Double = 0
    var timerPausedAt: Date!
    var shouldUnwindToTable: Bool!

    override func viewDidLoad() {
        super.viewDidLoad()

        if let workout = workout {
            // Updating an existing workout.
            showDatepickers()
            navigationBar.title = "Edit Workout"
            segmentedControl.isHidden = true
            segmentedControl.selectedSegmentIndex = 1
            startTimePicker.setDate(workout.start, animated: false)
            endTimePicker.setDate(workout.end, animated: false)
            saveButton.isEnabled = false

            guard let user = user else {
                self.displayAlert(title: "Something went wrong.", message: "There was a problem with the workout you selected.")
                os_log("Tried to edit workout where user was nil", log: OSLog.default, type: .error)
                return
            }
            workout.user = user

            let deleteWorkoutButton = UIButton(type: .system)
            let parentHeight = view.frame.size.height
            let parentWidth = view.frame.size.width
            deleteWorkoutButton.frame = CGRect(x: 20, y: parentHeight - 78, width: parentWidth - 40, height: 38)
            deleteWorkoutButton.backgroundColor = .red
            deleteWorkoutButton.addTarget(self, action: #selector(deleteButtonPressed), for: .touchUpInside)
            deleteWorkoutButton.setTitle("Delete Workout", for: .normal)
            deleteWorkoutButton.titleLabel?.font = .systemFont(ofSize: 21)
            deleteWorkoutButton.setTitleColor(.white, for: .normal)
            self.view.addSubview(deleteWorkoutButton)
        } else {
            // Adding a new workout.
            showStopwatch()
            segmentedControl.isHidden = false
            endTimePicker.setDate(endTimePicker.date + minute, animated: false)
        }

        // Styles
        startButton.layer.cornerRadius = 0.5 * startButton.bounds.width
        resetButton.layer.cornerRadius = 0.5 * resetButton.bounds.width
        resetButton.layer.borderWidth = 1
        disableResetButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func saveTimerToBackground() {
        timerPausedAt = Date.init()
        timer.invalidate()
    }

    func restoreTimerFromBackground() {
        numberOfSeconds += Date.init().timeIntervalSince(timerPausedAt)
        startTimer()
    }

    // MARK: - Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        if running {
            let alert = UIAlertController(title: "Are you sure you want to cancel?", message: "Your current workout will be lost.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Back to workout", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in self.dismiss(animated: true, completion: nil) }))
            present(alert, animated: true)
        } else {
            unwindToPreviousScreen()
        }
    }

    @IBAction func save(_ sender: UIBarButtonItem) {
        if numberOfSeconds == 0 && segmentedControl.selectedSegmentIndex == 0 {
            self.displayAlert(title: "Please enter a workout.", message: "You can enter a workout via the timer or the supplied date pickers.")
            return
        } else if running {
            stopTimer()
        }

        let confirmationAlert = UIAlertController(title: "Save this workout?", message: "", preferredStyle: .alert)
        confirmationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            if let workout = self.workout {
                // Update the workout.
                let copy = workout.copy()
                copy.start = self.startTimePicker.date
                copy.end = self.endTimePicker.date
                self.updateWorkout(workout: copy, completion: {
                    self.updateWorkoutDelegate?.update(workout: copy)

                    // If we were supposed to go back to the table view controller but the date changed, return to the calendar
                    if self.shouldUnwindToTable && !copy.end.isSameDayAs(workout.end) {
                        self.shouldUnwindToTable = false
                    }
                    self.unwindToPreviousScreen()
                })
            } else {
                // Add the workout.
                self.saveWorkout(completion: {
                    self.addWorkoutDelegate?.add(workout: $0)
                    self.dismiss(animated: true, completion: nil)
                })
            }
        }))
        confirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(confirmationAlert, animated: true)
    }

    // MARK: - Actions
    @IBAction func segmentedControlPressed(_ sender: UISegmentedControl) {
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            showStopwatch()
        case 1:
            showDatepickers()
        default:
            break
        }
    }

    @IBAction func startOrStopPressed(_ sender: UIButton) {
        if running {
            stopTimer()
            enableResetButton()
        } else {
            startTimer()
            disableResetButton()
        }
    }

    @IBAction func resetButtonPressed(_ sender: UIButton) {
        disableResetButton()
        resetTimer()
    }

    @IBAction func startDateChanged(_ sender: UIDatePicker) {
        if UInt64(startTimePicker.date.timeIntervalSince1970 / minute) >= UInt64(endTimePicker.date.timeIntervalSince1970 / minute) {
            endTimePicker.setDate(sender.date + minute, animated: true)
        }
        updateSaveButtonState()
    }

    @IBAction func endDateChanged(_ sender: UIDatePicker) {
        if UInt64(startTimePicker.date.timeIntervalSince1970 / minute) >= UInt64(endTimePicker.date.timeIntervalSince1970 / minute) {
            startTimePicker.setDate(sender.date - minute, animated: true)
        }
        updateSaveButtonState()
    }

    @objc func deleteButtonPressed(sender: UIButton!) {
        let confirmationAlert = UIAlertController(title: "Delete this workout?", message: nil, preferredStyle: .alert)
        confirmationAlert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: { _ in
            guard let workout = self.workout else {
                fatalError("Tried to delete workout but none was found")
            }
            self.deleteWorkout(workout: workout, completion: {
                self.deleteWorkoutDelegate?.delete(workout: workout)
                if self.shouldUnwindToTable, self.deleteWorkoutDelegate?.getNumberOfRemainingWorkouts() == 1 {
                    self.shouldUnwindToTable = false
                }
                self.unwindToPreviousScreen()
            })
        }))
        confirmationAlert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(confirmationAlert, animated: true)
    }

    // MARK: Private methods
    private func showStopwatch() {
        stopWatchLabel.isHidden = false
        startButton.isHidden = false
        resetButton.isHidden = false
        startTimePicker.isHidden = true
        endTimePicker.isHidden = true
    }

    private func showDatepickers() {
        stopWatchLabel.isHidden = true
        startButton.isHidden = true
        resetButton.isHidden = true
        startTimePicker.isHidden = false
        endTimePicker.isHidden = false
    }

    private func unwindToPreviousScreen() {
        if shouldUnwindToTable {
            performSegue(withIdentifier: "returnToWorkoutTable", sender: self)
        } else if workout != nil {
            performSegue(withIdentifier: "returnToViewController", sender: nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    private func startTimer() {
        running = true
        startButton.setTitle("Stop", for: .normal)
        startButton.backgroundColor = #colorLiteral(red: 1, green: 0, blue: 0, alpha: 1)
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
    }

    private func stopTimer() {
        running = false
        startButton.setTitle("Start", for: .normal)
        startButton.backgroundColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
        timer.invalidate()
    }

    private func resetTimer() {
        timer.invalidate()
        numberOfSeconds = 0
        stopWatchLabel.text = "00:00:00"
    }

    private func enableResetButton() {
        resetButton.isEnabled = true
        resetButton.layer.borderColor = #colorLiteral(red: 0, green: 0.4784313725, blue: 1, alpha: 1)
    }

    private func disableResetButton() {
        resetButton.isEnabled = false
        resetButton.layer.borderColor = #colorLiteral(red: 0.6666666865, green: 0.6666666865, blue: 0.6666666865, alpha: 1)
    }

    private func updateSaveButtonState() {
        if let workout = workout {
            if workout.start != startTimePicker.date || workout.end != endTimePicker.date {
                saveButton.isEnabled = true
            } else {
                saveButton.isEnabled = false
            }
        }
    }

    private func saveWorkout(completion: @escaping (_ workout: Workout) -> Void) {
        let activityIndicator = showActivityIndicator()

        var start: Date
        var end: Date
        // Calculate start and end based on the current visible screen as seconds since the unix epoch.
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            end = Date()
            start = Date(timeInterval: TimeInterval(-numberOfSeconds), since: end)
        case 1:
            start = startTimePicker.date
            end = endTimePicker.date
        default:
            fatalError("Unexpected input on segmented control: \(segmentedControl.selectedSegmentIndex)")
        }

        let workout = Workout(id: -1, user: user, start: start, end: end)
        Network.save(workout: workout, completion: { result in
            activityIndicator.removeFromSuperview()
            switch result {
            case .success(let resp):
                os_log("Saved workout with id %d", log: OSLog.default, type: .default, resp.id)
                workout.id = resp.id
                completion(workout)
            case .failure(let error):
                os_log("Could not save workout: %s", log: OSLog.default, type: .error, error.localizedDescription)
                self.displayAlert(title: "Something went wrong.", message: "Sorry, we couldn't save your workout. Please try again.")
            }
        })
    }

    private func updateWorkout(workout: Workout, completion: @escaping () -> Void) {
        let activityIndicator = showActivityIndicator()
        Network.update(workout: workout, completion: { result in
            activityIndicator.removeFromSuperview()
            switch result {
            case .success(_):
                os_log("Updated workout with id %d", log: OSLog.default, type: .default, workout.id)
                completion()
            case .failure(let error):
                os_log("Could not save workout: %s", log: OSLog.default, type: .error, error.localizedDescription)
                self.displayAlert(title: "Something went wrong.", message: "Sorry, we couldn't save your workout. Please try again.")
            }
        })
    }

    private func deleteWorkout(workout: Workout, completion: @escaping () -> Void) {
        let activityIndicator = showActivityIndicator()
        Network.delete(workout: workout, completion: { result in
            activityIndicator.removeFromSuperview()
            switch result {
            case .success(_):
                os_log("Deleted workout with id %d", log: OSLog.default, type: .default, workout.id)
                completion()
            case .failure(let error):
                os_log("Could not delete workout with id %d", log: OSLog.default, type: .error, error.localizedDescription)
                self.displayAlert(title: "Something went wrong.", message: "Sorry, we couldn't save your workout. Please try again.")
            }
        })
    }

    @objc private func updateTimer() {
        numberOfSeconds = numberOfSeconds + 1
        let hours = Int(numberOfSeconds) / (60 * 60)
        let minutes = Int(numberOfSeconds) / 60
        let seconds = Int(numberOfSeconds.rounded()) % 60
        stopWatchLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
