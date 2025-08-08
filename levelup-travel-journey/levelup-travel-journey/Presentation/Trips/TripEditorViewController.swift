//  TripEditorViewController.swift
//  My Travel
//
//  Simple editor to create or edit a Trip (name, destination, dates).

import UIKit

final class TripEditorViewController: UIViewController {
    var completion: (() -> Void)?

    private let nameField = UITextField()
    private let destinationField = UITextField()
    private let startPicker = UIDatePicker()
    private let endPicker = UIDatePicker()

    private let saveButton = UIBarButtonItem(barButtonSystemItem: .save, target: nil, action: nil)

    private let tripToEdit: Trip?
    private let repo = CoreDataTripRepository()

    init(trip: Trip? = nil) {
        self.tripToEdit = trip
        super.init(nibName: nil, bundle: nil)
        if trip == nil {
            title = "New Trip"
        } else {
            title = "Edit Trip"
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.auroraBackground
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "xmark"), style: .plain, target: self, action: #selector(closeTapped))
        saveButton.target = self
        saveButton.action = #selector(saveTapped)
        navigationItem.rightBarButtonItem = saveButton

        configureFields()
        layout()
        bindIfEditing()
    }

    private func configureFields() {
        nameField.placeholder = "Trip name"
        destinationField.placeholder = "Destination"

        for tf in [nameField, destinationField] {
            tf.borderStyle = .roundedRect
            tf.translatesAutoresizingMaskIntoConstraints = false
        }

        startPicker.datePickerMode = .date
        endPicker.datePickerMode = .date
        if #available(iOS 13.4, *) {
            startPicker.preferredDatePickerStyle = .wheels
            endPicker.preferredDatePickerStyle = .wheels
        }
        startPicker.translatesAutoresizingMaskIntoConstraints = false
        endPicker.translatesAutoresizingMaskIntoConstraints = false
    }

    private func layout() {
        let stack = UIStackView(arrangedSubviews: [nameField, destinationField, startPicker, endPicker])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])
    }

    private func bindIfEditing() {
        guard let t = tripToEdit else { return }
        nameField.text = t.name
        destinationField.text = t.destination
        startPicker.date = t.startDate
        endPicker.date = t.endDate
    }

    @objc private func closeTapped() { dismiss(animated: true) }

    @objc private func saveTapped() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let dest = destinationField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty, !dest.isEmpty else { return }
        let start = startPicker.date
        let end = endPicker.date
        guard end >= start else { return }

        do {
            if let t = tripToEdit {
                t.name = name
                t.destination = dest
                t.startDate = start
                t.endDate = end
                try t.managedObjectContext?.save()
            } else {
                _ = try repo.create(name: name, destination: dest, startDate: start, endDate: end, notes: nil)
            }
            dismiss(animated: true) { [weak self] in self?.completion?() }
        } catch {
            print("Save failed:", error)
        }
    }
}
