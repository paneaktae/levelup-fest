//  PlaceListViewController.swift
//  My Travel
//
//  Shows places grouped by dayIndex for a trip. Add/Edit/Delete, simple time overlap check.

import UIKit

final class PlaceListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let trip: Trip
    private let tableView = UITableView(frame: .zero, style: .insetGrouped)
    private var grouped: [Int16: [Place]] = [:]
    private var sortedKeys: [Int16] = []
    private let repo = CoreDataPlaceRepository()
    private let searchController = UISearchController(searchResultsController: nil)

    init(trip: Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
        title = "Places"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.auroraBackground
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(systemItem: .add, primaryAction: UIAction(handler: { [weak self] _ in self?.addTapped() })),
            UIBarButtonItem(image: UIImage(systemName: "creditcard"), style: .plain, target: self, action: #selector(showExpenses)),
            UIBarButtonItem(image: UIImage(systemName: "chart.bar"), style: .plain, target: self, action: #selector(showSummary))
        ]
        setupSearch()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.dataSource = self
        tableView.delegate = self
        view.addSubview(tableView)
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        refresh()
    }

    private func refresh() {
        do {
            let q = searchController.searchBar.text
            let places = try repo.fetch(for: trip, search: q)
            let groupedDict = Dictionary(grouping: places, by: { $0.dayIndex })
            grouped = groupedDict.mapValues { $0.sorted(by: { ($0.startTime ?? .distantPast) < ($1.startTime ?? .distantPast) }) }
            sortedKeys = grouped.keys.sorted()
            tableView.reloadData()
        } catch {
            print("fetch places failed", error)
        }
    }

    private func setupSearch() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search places"
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    @objc private func addTapped() {
        showEditor(place: nil)
    }

    private func showEditor(place: Place?) {
        let editor = PlaceEditorViewController(trip: trip, place: place)
        editor.onSaved = { [weak self] in self?.refresh() }
        navigationController?.pushViewController(editor, animated: true)
    }

    @objc private func showExpenses() {
        let vc = ExpenseListViewController(trip: trip)
        navigationController?.pushViewController(vc, animated: true)
    }

    @objc private func showSummary() {
        let vc = ExpenseSummaryViewController(trip: trip)
        navigationController?.pushViewController(vc, animated: true)
    }

    // MARK: Table
    func numberOfSections(in tableView: UITableView) -> Int { sortedKeys.count }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { "Day \(sortedKeys[section] + 1)" }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { grouped[sortedKeys[section]]?.count ?? 0 }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let key = sortedKeys[indexPath.section]
        if let p = grouped[key]?[indexPath.row] {
            cell.textLabel?.text = p.name
            let fmt = DateFormatter(); fmt.timeStyle = .short
            if let s = p.startTime, let e = p.endTime {
                cell.detailTextLabel?.text = "\(fmt.string(from: s)) - \(fmt.string(from: e))"
            } else {
                cell.detailTextLabel?.text = p.notes
            }
            cell.accessoryType = .disclosureIndicator
        }
        cell.backgroundColor = Theme.auroraCard
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let key = sortedKeys[indexPath.section]
        if let p = grouped[key]?[indexPath.row] {
            showEditor(place: p)
        }
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            guard let self else { completion(false); return }
            let key = self.sortedKeys[indexPath.section]
            guard let p = self.grouped[key]?[indexPath.row] else { completion(false); return }
            do {
                try self.repo.delete(p)
                self.refresh()
                completion(true)
            } catch {
                completion(false)
            }
        }
        deleteAction.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

extension PlaceListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        refresh()
    }
}
