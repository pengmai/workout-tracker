//
//  ViewController.swift
//  iWorkout
//
//  Created by Jacob Peng on 2018-04-18.
//  Copyright © 2018 Jacob Peng. All rights reserved.
//

import UIKit
import JTAppleCalendar

class ViewController: UIViewController {
    // MARK: - Properties
    @IBOutlet weak var calendarHeader: UILabel!
    @IBOutlet weak var calendarView: JTAppleCalendarView!

    var state: LoginResponse!

    let formatter = DateFormatter()
    let outsideMonthColor = UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 0.5)
    let monthColor = UIColor.black

    override func viewDidLoad() {
        super.viewDidLoad()

        let activityIndicator = showActivityIndicator()
        let token = "5FN/5uQhaN20J8TfiBDgsLm0+W58mpIoxE9G05AyQrs="
        Network.loadInitialState(token: token, completion: {
            activityIndicator.removeFromSuperview()
            switch $0 {
            case .success(let resp):
                print("Response: \(resp as AnyObject)")
                self.state = resp
            case .failure(let err):
                print("Error: \(err)")
            }
        })

        // Do any additional setup after loading the view, typically from a nib.
        setupCalendarView()
    }

    private func setupCalendarView() {
        calendarView.visibleDates(handleCalendarHeader)
    }

    private func handleCalendarHeader(visibleDates: DateSegmentInfo) {
        guard let date = visibleDates.monthDates.first?.date else { return }
        formatter.dateFormat = "MMMM yyyy"
        calendarHeader.text = formatter.string(from: date)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

// MARK: - Calendar settings
extension ViewController: JTAppleCalendarViewDelegate, JTAppleCalendarViewDataSource {
    func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {
        formatter.dateFormat = "yyyy MM dd"
        formatter.timeZone = Calendar.current.timeZone
        formatter.locale = Calendar.current.locale

        let startDate = formatter.date(from: "2018 04 01")!
        let now = Date()

        return ConfigurationParameters(
            startDate: startDate,
            endDate: now,
            generateOutDates: .tillEndOfRow
        )
    }

    func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {
        let calendarCell = cell as! CalendarCell
        configureVisibleCell(cell: calendarCell, cellState: cellState, date: date)
    }

    func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
        print(date)
        print(cellState)
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

        if cellState.dateBelongsTo == .thisMonth {
            if Calendar.current.compare(date, to: Date(), toGranularity: .day) == .orderedSame {
                cell.dateLabel.textColor = .red
            } else {
                cell.dateLabel.textColor = monthColor
            }
        } else {
            cell.dateLabel.textColor = outsideMonthColor
        }
    }
}
