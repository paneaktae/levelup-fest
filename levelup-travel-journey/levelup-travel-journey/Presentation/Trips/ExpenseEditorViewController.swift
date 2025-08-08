//  ExpenseEditorViewController.swift
//  My Travel
//
//  Editor for THB expenses. Optionally compute THB from another currency using user-provided FX.

import UIKit

final class ExpenseEditorViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    var onSaved: (() -> Void)?

    private let amountField = UITextField()
    private let categoryField = UITextField()
    private let noteField = UITextField()

    private let convertAmountField = UITextField()
    private let convertRateField = UITextField()
    private let convertResultLabel = UILabel()
    private let convertButton = UIButton(type: .system)

    private let imageView = UIImageView()
    private let addPhotoButton = UIButton(type: .system)

    private let repo = CoreDataExpenseRepository()
    private let trip: Trip
    private var attachmentPath: String?

    init(trip: Trip) {
        self.trip = trip
        super.init(nibName: nil, bundle: nil)
        title = "New Expense"
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.auroraBackground
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(saveTapped))
        setupUI()
    }

    private func setupUI() {
        amountField.placeholder = "Amount (THB)"
        amountField.keyboardType = .decimalPad
        categoryField.placeholder = "Category"
        noteField.placeholder = "Note (optional)"
        for tf in [amountField, categoryField, noteField, convertAmountField, convertRateField] {
            tf.borderStyle = .roundedRect
            tf.translatesAutoresizingMaskIntoConstraints = false
        }

        convertAmountField.placeholder = "Foreign amount"
        convertRateField.placeholder = "Rate → THB"
        convertButton.setImage(UIImage(systemName: "arrow.triangle.2.circlepath"), for: .normal)
        convertButton.setTitle(" Convert", for: .normal)
        convertButton.addTarget(self, action: #selector(convertTapped), for: .touchUpInside)

        imageView.contentMode = .scaleAspectFit
        imageView.layer.borderWidth = 1
        imageView.layer.borderColor = UIColor.separator.cgColor
        imageView.heightAnchor.constraint(equalToConstant: 160).isActive = true
        addPhotoButton.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        addPhotoButton.setTitle(" Add Photo", for: .normal)
        addPhotoButton.addTarget(self, action: #selector(addPhotoTapped), for: .touchUpInside)

        convertResultLabel.textColor = .secondaryLabel
        convertResultLabel.numberOfLines = 0

        let convertRow = UIStackView(arrangedSubviews: [convertAmountField, convertRateField, convertButton])
        convertRow.axis = .horizontal
        convertRow.spacing = 8
        convertRow.distribution = .fillEqually

        let stack = UIStackView(arrangedSubviews: [amountField, categoryField, noteField, convertRow, convertResultLabel, imageView, addPhotoButton])
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

    @objc private func convertTapped() {
        let amount = Decimal(string: convertAmountField.text ?? "") ?? 0
        let rate = Decimal(string: convertRateField.text ?? "") ?? 0
        let thb = ExpenseCalculatorService.convertToTHB(amount: amount, rateToTHB: rate)
        convertResultLabel.text = "Converted: ฿\(thb)"
        if amountField.text?.isEmpty ?? true { amountField.text = "\(thb)" }
    }

    @objc private func addPhotoTapped() {
        let picker = UIImagePickerController()
        picker.delegate = self
        picker.sourceType = .photoLibrary
        present(picker, animated: true)
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true)
        if let image = info[.originalImage] as? UIImage {
            imageView.image = image
            do {
                attachmentPath = try AttachmentStore.saveImage(image)
            } catch {
                print("Save image failed", error)
            }
        }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { picker.dismiss(animated: true) }

    @objc private func saveTapped() {
        let amount = Decimal(string: amountField.text ?? "") ?? 0
        let category = (categoryField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let note = (noteField.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard amount > 0, !category.isEmpty else { return }
        do {
            _ = try repo.create(for: trip, amountTHB: amount, category: category, note: note.isEmpty ? nil : note, createdAt: Date(), originalAmount: nil, originalCurrency: nil, fxRateUsed: nil, attachmentPath: attachmentPath)
            navigationController?.popViewController(animated: true)
            onSaved?()
        } catch {
            print("Save expense failed", error)
        }
    }
}
