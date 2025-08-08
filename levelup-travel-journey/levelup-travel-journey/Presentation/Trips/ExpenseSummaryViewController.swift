//  ExpenseSummaryViewController.swift
//  My Travel
//
//  Shows simple THB-only summary grouped by Day or by Category with a lightweight bar chart.

import UIKit

final class ExpenseSummaryViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    enum Mode: Int { case byDay = 0, byCategory = 1 }

    private let trip: Trip
    private let repo = CoreDataExpenseRepository()

    private var items: [Expense] = []
    private var totalsByDay: [(date: Date, total: Decimal)] = []
    private var totalsByCategory: [(category: String, total: Decimal)] = []
    private var overallTotal: Decimal = 0

    private let segmented = UISegmentedControl(items: ["By Day", "By Category"])
    private let totalLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)

    private let numberFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = "THB"
        nf.currencySymbol = "฿"
        nf.maximumFractionDigits = 2
        return nf
    }()

    init(trip: Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
        title = "Summary"
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.auroraBackground

        segmented.selectedSegmentIndex = 0
        segmented.addTarget(self, action: #selector(modeChanged), for: .valueChanged)
        segmented.translatesAutoresizingMaskIntoConstraints = false
        segmented.selectedSegmentTintColor = Theme.auroraAccent

        totalLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        totalLabel.textAlignment = .center
        totalLabel.translatesAutoresizingMaskIntoConstraints = false

        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(segmented)
        view.addSubview(totalLabel)
        view.addSubview(tableView)

        NSLayoutConstraint.activate([
            segmented.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            segmented.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            segmented.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            totalLabel.topAnchor.constraint(equalTo: segmented.bottomAnchor, constant: 12),
            totalLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            totalLabel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16),

            tableView.topAnchor.constraint(equalTo: totalLabel.bottomAnchor, constant: 8),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        refresh()
    }

    @objc private func modeChanged() {
        tableView.reloadData()
        updateHeader()
    }

    private func refresh() {
        do {
            items = try repo.fetch(for: trip)
        } catch {
            items = []
        }
        computeSummaries()
        updateHeader()
        tableView.reloadData()
    }

    private func computeSummaries() {
        overallTotal = 0
        var byDay: [Date: Decimal] = [:]
        var byCategory: [String: Decimal] = [:]
        let cal = Calendar.current

        for e in items {
            let amount = e.amountTHB.decimalValue
            overallTotal += amount
            let day = cal.startOfDay(for: e.createdAt)
            byDay[day, default: 0] += amount
            byCategory[e.category, default: 0] += amount
        }

        totalsByDay = byDay
            .map { ($0.key, $0.value) }
            .sorted { $0.0 < $1.0 }

        totalsByCategory = byCategory
            .map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
    }

    private func updateHeader() {
        let totalText = numberFormatter.string(from: NSDecimalNumber(decimal: overallTotal)) ?? "฿0"
        totalLabel.text = "Total: \(totalText)"
    }

    // MARK: - Table

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if segmented.selectedSegmentIndex == Mode.byDay.rawValue { return totalsByDay.count }
        return totalsByCategory.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        cell.selectionStyle = .none

        // Determine data set
        if segmented.selectedSegmentIndex == Mode.byDay.rawValue {
            let row = totalsByDay[indexPath.row]
            let df = DateFormatter()
            df.dateStyle = .medium
            df.timeStyle = .none
            cell.textLabel?.text = df.string(from: row.date)
            let amountText = numberFormatter.string(from: NSDecimalNumber(decimal: row.total)) ?? "฿0"
            cell.detailTextLabel?.text = amountText
        } else {
            let row = totalsByCategory[indexPath.row]
            cell.textLabel?.text = row.category
            let amountText = numberFormatter.string(from: NSDecimalNumber(decimal: row.total)) ?? "฿0"
            cell.detailTextLabel?.text = amountText
        }

        // Simple horizontal bar graph in the cell background
        addBar(to: cell, at: indexPath)
        cell.backgroundColor = Theme.auroraCard
        return cell
    }

    private func addBar(to cell: UITableViewCell, at indexPath: IndexPath) {
        // Remove previous bar layers
        cell.contentView.layer.sublayers?.removeAll(where: { $0.name == "barLayer" })

        let value: Decimal
        let maxValue: Decimal
        if segmented.selectedSegmentIndex == Mode.byDay.rawValue {
            value = totalsByDay[indexPath.row].total
            maxValue = totalsByDay.map { $0.total }.max() ?? 0
        } else {
            value = totalsByCategory[indexPath.row].total
            maxValue = totalsByCategory.map { $0.total }.max() ?? 0
        }
        guard maxValue > 0, value > 0 else { return }

        let width = cell.contentView.bounds.width - 32 // padding
        let ratio = NSDecimalNumber(decimal: value).doubleValue / NSDecimalNumber(decimal: maxValue).doubleValue
        let barWidth = CGFloat(ratio) * width

        let barLayer = CALayer()
        barLayer.name = "barLayer"
        barLayer.backgroundColor = Theme.auroraAccent.withAlphaComponent(0.25).cgColor
        let height: CGFloat = 8
        let y = cell.contentView.bounds.height - height - 8
        barLayer.frame = CGRect(x: 16, y: y, width: barWidth, height: height)
        cell.contentView.layer.addSublayer(barLayer)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Re-layout bars on rotation/size changes
        for case let cell as UITableViewCell in tableView.visibleCells {
            if let indexPath = tableView.indexPath(for: cell) {
                addBar(to: cell, at: indexPath)
            }
        }
    }
}
