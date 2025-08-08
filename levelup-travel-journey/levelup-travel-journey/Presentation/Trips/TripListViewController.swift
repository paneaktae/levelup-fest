//  TripListViewController.swift
//  My Travel
//
//  Shows list of trips, supports add/edit/delete, with empty state.

import UIKit
import CoreData

final class TripListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    weak var router: TripListRouter?

    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyStack: UIStackView = {
        let iv = UIImageView(image: UIImage(systemName: "airplane.circle.fill"))
        iv.tintColor = Theme.auroraAccent
        iv.contentMode = .scaleAspectFit
        iv.heightAnchor.constraint(equalToConstant: 64).isActive = true
        iv.widthAnchor.constraint(equalTo: iv.heightAnchor).isActive = true
        let l = UILabel()
        l.text = "No trips yet\nTap + to create"
        l.textAlignment = .center
        l.numberOfLines = 0
        l.textColor = .secondaryLabel
        let stack = UIStackView(arrangedSubviews: [iv, l])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private var trips: [Trip] = []
    private let repo = CoreDataTripRepository()
    private let searchController = UISearchController(searchResultsController: nil)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.auroraBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .add, primaryAction: UIAction(handler: { [weak self] _ in self?.addTapped() }))
        setupSearch()
        setupTable()
        refresh()
    }

    private func setupSearch() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search trips"
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func setupTable() {
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

        view.addSubview(emptyStack)
        NSLayoutConstraint.activate([
            emptyStack.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            emptyStack.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor),
        ])
    }

    private func refresh() {
        do {
            let query = searchController.searchBar.text
            trips = try repo.fetchAll(search: query)
            tableView.reloadData()
            emptyStack.isHidden = !trips.isEmpty
        } catch {
            print("Failed to fetch trips:", error)
        }
    }

    @objc private func addTapped() {
        router?.showCreateTrip { [weak self] in self?.refresh() }
    }

    // MARK: UITableViewDataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { trips.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let t = trips[indexPath.row]
        cell.textLabel?.text = t.name
        let fmt = DateFormatter()
        fmt.dateStyle = .medium
        cell.detailTextLabel?.text = "\(t.destination) • \(fmt.string(from: t.startDate)) - \(fmt.string(from: t.endDate))"
        cell.accessoryType = .disclosureIndicator
        cell.backgroundColor = Theme.auroraCard
        cell.textLabel?.textColor = .label
        cell.detailTextLabel?.textColor = .secondaryLabel
        return cell
    }

    // MARK: UITableViewDelegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let trip = trips[indexPath.row]
        router?.showPlaces(for: trip)
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            guard let self else { completion(false); return }
            do {
                try self.repo.delete(self.trips[indexPath.row])
                self.trips.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                self.emptyStack.isHidden = !self.trips.isEmpty
                completion(true)
            } catch {
                completion(false)
            }
        }
        deleteAction.image = UIImage(systemName: "trash")
        let editAction = UIContextualAction(style: .normal, title: nil) { [weak self] _, _, completion in
            guard let self else { completion(false); return }
            let trip = self.trips[indexPath.row]
            self.router?.showEditTrip(trip) { [weak self] in self?.refresh() }
            completion(true)
        }
        editAction.image = UIImage(systemName: "pencil")
        editAction.backgroundColor = Theme.auroraSecondary
        return UISwipeActionsConfiguration(actions: [deleteAction, editAction])
    }
}

extension TripListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        refresh()
    }
}
