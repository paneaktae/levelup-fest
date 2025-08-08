//  PlaceEditorViewController.swift
//  My Travel
//
//  Simple editor for Place with time range, notes, optional coordinates, and overlap check within day.

import UIKit

final class PlaceEditorViewController: UIViewController {
    var onSaved: (() -> Void)?

    private let nameField = UITextField()
    private let dayStepper = UIStepper()
    private let dayLabel = UILabel()
    private let startPicker = UIDatePicker()
    private let endPicker = UIDatePicker()
    private let latField = UITextField()
    private let lngField = UITextField()
    private let notesView = UITextView()

    private let repo = CoreDataPlaceRepository()
    private let trip: Trip
    private let placeToEdit: Place?

    init(trip: Trip, place: Place?) {
        self.trip = trip
        self.placeToEdit = place
        super.init(nibName: nil, bundle: nil)
        title = place == nil ? "New Place" : "Edit Place"
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.auroraBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        setupUI()
        bindIfEditing()
    }

    private func setupUI() {
        nameField.placeholder = "Place name"
        nameField.borderStyle = .roundedRect
        latField.placeholder = "Latitude (optional)"
        lngField.placeholder = "Longitude (optional)"
        latField.keyboardType = .decimalPad
        lngField.keyboardType = .decimalPad
        latField.borderStyle = .roundedRect
        lngField.borderStyle = .roundedRect

        dayStepper.minimumValue = 0
        dayStepper.maximumValue = 365
        dayStepper.addTarget(self, action: #selector(dayChanged), for: .valueChanged)
        dayLabel.textAlignment = .right

        startPicker.datePickerMode = .time
        endPicker.datePickerMode = .time
        if #available(iOS 13.4, *) {
            startPicker.preferredDatePickerStyle = .wheels
            endPicker.preferredDatePickerStyle = .wheels
        }

        notesView.layer.borderWidth = 1
        notesView.layer.borderColor = UIColor.separator.cgColor
        notesView.layer.cornerRadius = 6
        notesView.heightAnchor.constraint(equalToConstant: 120).isActive = true

        let dayTitle = iconLabel(systemName: "calendar", text: "Day")
        let startTitle = iconLabel(systemName: "clock", text: "Start time")
        let endTitle = iconLabel(systemName: "clock", text: "End time")
        let notesTitle = iconLabel(systemName: "note.text", text: "Notes")

        let dayRow = UIStackView(arrangedSubviews: [dayTitle, dayLabel, dayStepper])
        dayRow.axis = .horizontal
        dayRow.spacing = 8
        dayRow.distribution = .fill

        let stack = UIStackView(arrangedSubviews: [nameField, dayRow, startTitle, startPicker, endTitle, endPicker, latField, lngField, notesTitle, notesView])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        dayStepper.value = 0
        dayLabel.text = "1"
    }

    private func bindIfEditing() {
        guard let p = placeToEdit else { return }
        nameField.text = p.name
        dayStepper.value = Double(p.dayIndex)
        dayLabel.text = String(Int(p.dayIndex) + 1)
        if let s = p.startTime { startPicker.date = s }
        if let e = p.endTime { endPicker.date = e }
        if p.latitude != 0 { latField.text = String(p.latitude) }
        if p.longitude != 0 { lngField.text = String(p.longitude) }
        notesView.text = p.notes
    }

    @objc private func dayChanged() {
        dayLabel.text = String(Int(dayStepper.value) + 1)
    }

    @objc private func saveTapped() {
        let name = nameField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !name.isEmpty else { return }
        let dayIndex = Int16(dayStepper.value)
        let start = startPicker.date
        let end = endPicker.date
        guard end >= start else { return }

        let lat = Double(latField.text ?? "")
        let lng = Double(lngField.text ?? "")
        let notes = notesView.text?.isEmpty == true ? nil : notesView.text

        // Simple overlap check in same day
        do {
            let existing = try CoreDataPlaceRepository().fetch(for: trip).filter { $0.dayIndex == dayIndex && $0 != placeToEdit }
            if let conflict = existing.first(where: { (a) -> Bool in
                guard let aStart = a.startTime, let aEnd = a.endTime else { return false }
                return (aStart <= end && start <= aEnd)
            }) {
                print("Time overlap with: \(conflict.name)")
                // For MVP just block save
                return
            }
        } catch { }

        do {
            if let p = placeToEdit {
                p.name = name
                p.dayIndex = dayIndex
                p.startTime = start
                p.endTime = end
                p.latitude = lat ?? 0
                p.longitude = lng ?? 0
                p.notes = notes
                try p.managedObjectContext?.save()
            } else {
                _ = try repo.create(for: trip, name: name, dayIndex: dayIndex, startTime: start, endTime: end, latitude: lat, longitude: lng, notes: notes)
            }
            navigationController?.popViewController(animated: true)
            onSaved?()
        } catch {
            print("save place failed", error)
        }
    }

    private func iconLabel(systemName: String, text: String) -> UIView {
        let iv = UIImageView(image: UIImage(systemName: systemName))
        iv.tintColor = Theme.auroraAccent
        iv.setContentHuggingPriority(.required, for: .horizontal)
        let label = UILabel()
        label.text = text
        let row = UIStackView(arrangedSubviews: [iv, label])
        row.axis = .horizontal
        row.spacing = 6
        return row
    }
}

private extension UILabel {
    convenience init(text: String) {
        self.init()
        self.text = text
        self.translatesAutoresizingMaskIntoConstraints = false
    }
}
