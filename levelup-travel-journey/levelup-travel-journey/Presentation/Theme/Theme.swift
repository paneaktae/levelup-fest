//  Theme.swift
//  My Travel
//
//  Aurora theme: vibrant gradients, teal/purple accents, rounded surfaces.

import UIKit

enum Theme {
    // Aurora palette (dynamic for light/dark)
    static var auroraPrimary: UIColor { UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.55, green: 0.82, blue: 0.98, alpha: 1) : UIColor(red: 0.00, green: 0.64, blue: 0.93, alpha: 1) // sky blue
    }}
    static var auroraSecondary: UIColor { UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.67, green: 0.86, blue: 0.75, alpha: 1) : UIColor(red: 0.18, green: 0.80, blue: 0.44, alpha: 1) // green
    }}
    static var auroraAccent: UIColor { UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.83, green: 0.73, blue: 0.99, alpha: 1) : UIColor(red: 0.54, green: 0.36, blue: 0.94, alpha: 1) // purple
    }}
    static var auroraBackground: UIColor { UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.06, green: 0.07, blue: 0.10, alpha: 1) : UIColor.systemBackground
    }}
    static var auroraCard: UIColor { UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(red: 0.13, green: 0.15, blue: 0.20, alpha: 1) : UIColor.secondarySystemBackground
    }}

    static func applyGlobalAppearance() {
        let nav = UINavigationBarAppearance()
        nav.configureWithOpaqueBackground()
        nav.backgroundColor = Theme.auroraPrimary
        nav.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 18, weight: .semibold)
        ]
        nav.largeTitleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.systemFont(ofSize: 32, weight: .bold)
        ]

        UINavigationBar.appearance().standardAppearance = nav
        UINavigationBar.appearance().scrollEdgeAppearance = nav
        UINavigationBar.appearance().tintColor = .white
        UINavigationBar.appearance().prefersLargeTitles = true

        let barButton = UIBarButtonItem.appearance()
        barButton.tintColor = .white

        UISegmentedControl.appearance().selectedSegmentTintColor = Theme.auroraAccent
        UISegmentedControl.appearance().setTitleTextAttributes([
            .foregroundColor: UIColor.white
        ], for: .selected)

        UITableView.appearance().separatorColor = Theme.auroraPrimary.withAlphaComponent(0.2)
    }
}
