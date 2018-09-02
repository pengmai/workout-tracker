//
//  ChartsViewController.swift
//  iWorkout
//
//  Created by Jacob Peng on 2018-08-22.
//  Copyright © 2018 Jacob Peng. All rights reserved.
//

import UIKit
import Charts

class ChartsViewController: UIViewController {
    @IBOutlet weak var daysLabel: UILabel!
    @IBOutlet weak var workoutGroupChart: LineChartView!

    var workouts: [Date : [Workout]]!
    var groupingFunc: ((Date, Date) -> Bool)!
    var labels: [String]?
    let formatter = DateFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()

        let now = Date()
        if let last = workouts.reduce([], { $0 + $1.value }).sorted(by: { $0.end < $1.end }).last,
            let since = Calendar.current.dateComponents([.day], from: last.end, to: now).day {
            if since == 1 {
                daysLabel.text = "1 day"
            } else {
                daysLabel.text = "\(since) days"
            }
        }

        groupingFunc = areInSameMonth(first:second:)

        setupGroupChart()
        updateGroupChart()
    }

    func setupGroupChart() {
        formatter.dateFormat = "MMM yyyy"
//        workoutGroupChart.isUserInteractionEnabled = false
        workoutGroupChart.chartDescription?.enabled = false
        workoutGroupChart.rightAxis.enabled = false
        workoutGroupChart.legend.enabled = false
        let xAxis = workoutGroupChart.xAxis
        xAxis.granularity = 1

        let leftAxis = workoutGroupChart.leftAxis
        leftAxis.axisMinimum = 0
        leftAxis.granularity = 1
        workoutGroupChart.animate(yAxisDuration: 1)

        let marker = BalloonMarker(color: .darkGray,
                                   font: .systemFont(ofSize: 12),
                                   textColor: .white,
                                   insets: UIEdgeInsets(top: 8, left: 8, bottom: 20, right: 8))
        marker.chartView = workoutGroupChart
        marker.minimumSize = CGSize(width: 80, height: 40)
        workoutGroupChart.marker = marker
    }

    private func areInSameMonth(first: Date, second: Date) -> Bool {
        return Calendar.current.isDate(first, equalTo: second, toGranularity: .month)
    }

    func updateGroupChart() {
        let workoutValues = workouts.reduce([], { (result, workoutsForDay) -> [(Date, Int)] in
            if let i = result.index(where: { self.groupingFunc($0.0, workoutsForDay.key) }) {
                var resultCopy = result
                resultCopy[i].1 += workoutsForDay.value.count
                return resultCopy
            } else {
                return result + [(workoutsForDay.key.firstDayOfMonth(), workoutsForDay.value.count)]
            }
        }).sorted { $0.0 < $1.0 } // Sort by date
        var entries = [ChartDataEntry]()
        var labels = [String]()

        if let start = workoutValues.first?.0 {
            var d = start
            let now = Date().firstDayOfMonth()
            var index = 0.0
            while d < now {
                if let value = workoutValues.first(where: { $0.0.isSameMonthAs(d) }) {
                    entries.append(ChartDataEntry(x: index, y: Double(value.1)))
                } else {
                    entries.append(ChartDataEntry(x: index, y: 0))
                }

                labels.append(formatter.string(from: d))
                index += 1
                d = Calendar.current.date(byAdding: .month, value: 1, to: d)!
            }
        }

        let set = LineChartDataSet(values: entries, label: nil)
        set.axisDependency = .left
        set.drawCirclesEnabled = true
        set.circleRadius = 5
        set.drawCircleHoleEnabled = true
        set.circleHoleRadius = 3
        set.lineWidth = 3
        set.fillAlpha = 0.26
        set.drawValuesEnabled = false
        let data = LineChartData(dataSet: set)

        workoutGroupChart.xAxis.valueFormatter = IndexAxisValueFormatter(values: labels)

        if let marker = workoutGroupChart.marker as? BalloonMarker {
            marker.labels = labels
        }

        workoutGroupChart.data = data
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
