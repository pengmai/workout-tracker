//
//  WorkoutTableViewController.swift
//  iWorkout
//
//  Created by Jacob Peng on 2018-08-12.
//  Copyright © 2018 Jacob Peng. All rights reserved.
//

import UIKit

class WorkoutTableViewController: UITableViewController {
    // MARK: - Properties
    let formatter = DateFormatter()
    var workouts: [Workout]!
    var user: Int!
    var updateWorkoutDelegate: UpdateWorkoutDelegate!
    var deleteWorkoutDelegate: DeleteWorkoutDelegate!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        //self.navigationItem.rightBarButtonItem = self.editButtonItem
        formatter.locale = Locale(identifier: "en_US")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return workouts.count
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let first = workouts.first {
            formatter.dateFormat = "MMMM d, yyyy"
            return formatter.string(from: first.end)
        }
        return nil
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "WorkoutTableCell", for: indexPath) as? WorkoutTableViewCell else {
            fatalError("Didn't get a WorkoutTableViewCell")
        }

        let workout = workouts[indexPath.row]

        formatter.dateFormat = "h:mm a"
        cell.startLabel.text = "\(formatter.string(from: workout.start)) - \(formatter.string(from: workout.end))"

        return cell
    }

    // Override to support editing the table view.
//    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
//        if editingStyle == .delete {
//            // Delete the row from the data source
//            workouts.remove(at: indexPath.row)
//            tableView.deleteRows(at: [indexPath], with: .fade)
//        } else if editingStyle == .insert {
//            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//        }
//    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        if let destination = segue.destination as? WorkoutViewController {
            guard let selectedCell = sender as? WorkoutTableViewCell else {
                fatalError("Didn't get WorkoutTableViewCell")
            }

            guard let indexPath = tableView.indexPath(for: selectedCell) else {
                fatalError("The selected path is not being displayed by the table")
            }

            destination.workout = workouts[indexPath.row]
            destination.user = user
            destination.shouldUnwindToTable = true
            destination.updateWorkoutDelegate = self
            destination.deleteWorkoutDelegate = self
        }
        // Pass the selected object to the new view controller.
    }

    @IBAction func unwindToTable(segue: UIStoryboardSegue) {
    }
}

extension WorkoutTableViewController: UpdateWorkoutDelegate {
    func update(workout: Workout) {
        // TODO: Decide what to do if the date of the workout has changed. 1) change the date? would require getting the list of workouts for the day from the parent. 2) have the workout disappear?
        // Update data in the parent.
        updateWorkoutDelegate.update(workout: workout)
        guard let i = workouts.firstIndex(where: { $0.id == workout.id }) else {
            fatalError("Tried to update workout that wasn't in the list")
        }

        workouts[i] = workout
        tableView.reloadRows(at: [IndexPath(row: i, section: 0)], with: .automatic)
    }
}

extension WorkoutTableViewController: DeleteWorkoutDelegate {
    func delete(workout: Workout) {
        deleteWorkoutDelegate.delete(workout: workout)
        guard let i = workouts.firstIndex(where: { $0.id == workout.id }) else {
            fatalError("Tried to delete workout that wasn't in the list")
        }

        workouts.remove(at: i)
        tableView.reloadData()
    }

    func getNumberOfRemainingWorkouts() -> Int {
        return workouts.count
    }
}
