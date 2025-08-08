//  ExpenseListViewController.swift
//  My Travel
//
//  Shows expenses for a trip. Add/Delete, and show THB amount & category.

import UIKit

final class ExpenseListViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let trip: Trip
    private let tableView = UITableView(frame: .zero, style: .plain)
    private var items: [Expense] = []
    private let repo = CoreDataExpenseRepository()
    private let searchController = UISearchController(searchResultsController: nil)

    init(trip: Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
        title = "Expenses"
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.auroraBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(systemItem: .add, primaryAction: UIAction(handler: { [weak self] _ in self?.addTapped() }))
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

    private func setupSearch() {
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search expenses"
        searchController.searchResultsUpdater = self
        navigationItem.searchController = searchController
        definesPresentationContext = true
    }

    private func refresh() {
        do { items = try repo.fetch(for: trip, search: searchController.searchBar.text) } catch { items = [] }
        tableView.reloadData()
    }

    @objc private func addTapped() {
        let editor = ExpenseEditorViewController(trip: trip)
        editor.onSaved = { [weak self] in self?.refresh() }
        navigationController?.pushViewController(editor, animated: true)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell(style: .subtitle, reuseIdentifier: "cell")
        let e = items[indexPath.row]
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencyCode = "THB"
        nf.currencySymbol = "฿"
        let amountText = nf.string(from: e.amountTHB) ?? "฿0"
        cell.textLabel?.text = "\(amountText) • \(e.category)"
        cell.detailTextLabel?.text = e.note
        cell.backgroundColor = Theme.auroraCard
        cell.accessoryView = UIImageView(image: UIImage(systemName: "chevron.right"))
        (cell.accessoryView as? UIImageView)?.tintColor = .tertiaryLabel
        return cell
    }

    func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
        let deleteAction = UIContextualAction(style: .destructive, title: nil) { [weak self] _, _, completion in
            guard let self else { completion(false); return }
            do {
                try self.repo.delete(self.items[indexPath.row])
                self.items.remove(at: indexPath.row)
                tableView.deleteRows(at: [indexPath], with: .automatic)
                completion(true)
            } catch {
                completion(false)
            }
        }
        deleteAction.image = UIImage(systemName: "trash")
        return UISwipeActionsConfiguration(actions: [deleteAction])
    }
}

extension ExpenseListViewController: UISearchResultsUpdating {
    func updateSearchResults(for searchController: UISearchController) {
        refresh()
    }
}
