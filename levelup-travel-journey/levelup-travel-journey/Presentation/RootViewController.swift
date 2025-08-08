//  RootViewController.swift
//  My Travel
//
//  Shows a simple centered label as landing screen for MVP.

import UIKit

final class RootViewController: UIViewController {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "My Travel"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textAlignment = .center
        label.textColor = .white
        return label
    }()

    private let headerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Theme.auroraBackground

        view.addSubview(headerView)
        headerView.addSubview(titleLabel)
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            headerView.heightAnchor.constraint(equalToConstant: 180),

            titleLabel.centerXAnchor.constraint(equalTo: headerView.centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: headerView.centerYAnchor)
        ])
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // Add gradient once we know frame
        if headerView.layer.sublayers?.first(where: { $0.name == "auroraGradient" }) == nil {
            let g = CAGradientLayer()
            g.name = "auroraGradient"
            g.frame = headerView.bounds
            g.colors = [Theme.auroraPrimary.cgColor, Theme.auroraAccent.cgColor]
            g.startPoint = CGPoint(x: 0, y: 0)
            g.endPoint = CGPoint(x: 1, y: 1)
            headerView.layer.insertSublayer(g, at: 0)
        } else {
            headerView.layer.sublayers?.first(where: { $0.name == "auroraGradient" })?.frame = headerView.bounds
        }
    }
}
