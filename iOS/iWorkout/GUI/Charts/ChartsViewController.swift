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
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var workoutGroupChart: LineChartView!
    @IBOutlet weak var workoutTimeChart: PieChartView!

    var workouts: [Date : [Workout]]!
    var groupingFunc: ((Date, Date) -> Bool)!
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
            detailLabel.text = "Since you last worked out"
            groupingFunc = areInSameMonth(first:second:)

            setupGroupChart()
            setupTimeChart()
            updateGroupChart()
            updateTimeChart()
            workoutGroupChart.isHidden = false
            workoutTimeChart.isHidden = false
        } else {
            daysLabel.text = "No workouts yet"
            detailLabel.text = "Add some workouts to see insights!"
            workoutGroupChart.isHidden = true
            workoutTimeChart.isHidden = true
        }
    }

    func setupGroupChart() {
        formatter.dateFormat = "MMM yyyy"
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

    func setupTimeChart() {
        workoutTimeChart.legend.enabled = false
        workoutTimeChart.chartDescription?.text = "Time of day you work out"
        workoutTimeChart.animate(xAxisDuration: 1)
        workoutTimeChart.highlightPerTapEnabled = false
    }

    private func areInSameMonth(first: Date, second: Date) -> Bool {
        return Calendar.current.isDate(first, equalTo: second, toGranularity: .month)
    }

    func updateGroupChart() {
        let workoutValues = workouts.reduce([], { (result, workoutsForDay) -> [(Date, Int)] in
            if let i = result.firstIndex(where: { self.groupingFunc($0.0, workoutsForDay.key) }) {
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
            while d <= now {
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

    func updateTimeChart() {
        /*
        Potential categories are:
        - 6 am to noon: morning
        - noon to 6pm: afternoon
        - 6pm to midnight: evening
        - midnight to 6 am: night
        */
        var groups = [0, 0, 0, 0]
        let labels = ["Night", "Morning", "Afternoon", "Evening"]
        let colours: [UIColor] = [
            UIColor(red: 105 / 255, green: 132 / 255, blue: 155 / 255, alpha: 1), // Dark blue
            UIColor(red: 232 / 255, green: 70 / 255, blue: 56 / 255, alpha: 1), // Red
            UIColor(red: 138 / 255, green: 243 / 255, blue: 255 / 255, alpha: 1), // Light blue
            UIColor(red: 45 / 255, green: 216 / 255, blue: 129 / 255, alpha: 1) // Green
        ]
        let workoutList = workouts.reduce([], { $0 + $1.value })
        workoutList.forEach {
            let group = getDateCategory(for: $0.end)
            groups[group] += 1
        }

        let entries = groups.enumerated().map { (PieChartDataEntry(value: 100 * (Double($0.element) / Double(workoutList.count)), label: labels[$0.offset]), colours[$0.offset]) }.filter { $0.0.value > 0 }
        let set = PieChartDataSet(values: entries.map({ $0.0 }), label: nil)
        set.colors = entries.map { $0.1 }
        set.valueLinePart1OffsetPercentage = 0.8
        set.valueLinePart1Length = 0.2
        set.valueLinePart2Length = 0.4
        set.yValuePosition = .outsideSlice
        let data = PieChartData(dataSet: set)

        let pFormatter = NumberFormatter()
        pFormatter.numberStyle = .percent
        pFormatter.maximumFractionDigits = 1
        pFormatter.multiplier = 1
        pFormatter.percentSymbol = "%"
        data.setValueFormatter(DefaultValueFormatter(formatter: pFormatter))
        data.setValueTextColor(.black)
        workoutTimeChart.data = data
    }

    private func getDateCategory(for date: Date) -> Int {
        let hour = Calendar.current.component(.hour, from: date)
        if 0 <= hour && hour < 6 {
            return 0
        } else if 6 <= hour && hour < 12 {
            return 1
        } else if 12 <= hour && hour < 18 {
            return 2
        } else {
            return 3
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
