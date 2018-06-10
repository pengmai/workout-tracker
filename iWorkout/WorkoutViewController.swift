//
//  WorkoutViewController.swift
//  iWorkout
//
//  Created by Jacob Peng on 2018-04-18.
//  Copyright © 2018 Jacob Peng. All rights reserved.
//

import UIKit

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
    @IBOutlet weak var saveButton: UIBarButtonItem!

    var running = false
    var timer = Timer()
    var numberOfSeconds: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        showStopwatch()

        endTimePicker.setDate(endTimePicker.date + minute, animated: false)

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

    // MARK: - Navigation
    @IBAction func cancel(_ sender: UIBarButtonItem) {
        if running {
            let alert = UIAlertController(title: "Are you sure you want to cancel?", message: "Your current workout will be lost.", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Back to workout", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Cancel", style: .destructive, handler: { _ in self.dismiss(animated: true, completion: nil) }))
            present(alert, animated: true)
        } else {
            dismiss(animated: true, completion: nil)
        }
    }

    @IBAction func save(_ sender: UIBarButtonItem) {
        if numberOfSeconds == 0 && segmentedControl.selectedSegmentIndex == 0 {
            let noWorkoutAlert = UIAlertController(title: "Please enter a workout.", message: "You can enter a workout via the timer or the supplied date pickers.", preferredStyle: .alert)
            noWorkoutAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(noWorkoutAlert, animated: true)
            return
        } else if (running) {
            stopTimer()
        }

        let confirmationAlert = UIAlertController(title: "Save this workout?", message: "", preferredStyle: .alert)
        confirmationAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: {action in
            self.saveWorkout(completion: { self.dismiss(animated: true, completion: nil) })
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
        print("Start/Stop button pressed")
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
    }

    @IBAction func endDateChanged(_ sender: UIDatePicker) {
        if UInt64(startTimePicker.date.timeIntervalSince1970 / minute) >= UInt64(endTimePicker.date.timeIntervalSince1970 / minute) {
            startTimePicker.setDate(sender.date - minute, animated: true)
        }
    }

    /*
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

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

    private func saveWorkout(completion: @escaping () -> Void) {
        let activityIndicator = showActivityIndicator()

        var start: UInt64
        var end: UInt64
        // Calculate start and end based on the current visible screen as seconds since the unix epoch.
        switch segmentedControl.selectedSegmentIndex {
        case 0:
            end = UInt64(Date().timeIntervalSince1970)
            start = end - UInt64(numberOfSeconds)
        case 1:
            start = UInt64(startTimePicker.date.timeIntervalSince1970)
            end = UInt64(endTimePicker.date.timeIntervalSince1970)
        default:
            fatalError("Unexpected input on segmented control: \(segmentedControl.selectedSegmentIndex)")
        }

        let workout = Workout(id: -1, user: 10, start: start, end: end)
        Network.save(workout: workout, completion: { result in
            switch result {
            case .success(let id):
                print("Saved workout with id \(id)")
                workout.id = id
            case .failure(let error):
                print("Could not save workout: \(error.localizedDescription)")
            }
            activityIndicator.removeFromSuperview()
            completion()
        })
    }

    @objc private func updateTimer() {
        numberOfSeconds = numberOfSeconds + 1
        let hours = numberOfSeconds / (60 * 60)
        let minutes = numberOfSeconds / 60
        let seconds = numberOfSeconds % 60
        stopWatchLabel.text = String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}
