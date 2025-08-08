//  AppCoordinator.swift
//  My Travel
//
//  A minimal coordinator to manage the root navigation stack.

import UIKit

final class AppCoordinator {
    private let window: UIWindow
    private var navigationController: UINavigationController?

    init(window: UIWindow) {
        self.window = window
    }

    func start() {
        let listVC = TripListViewController()
        listVC.router = self
        listVC.title = "Trips"
        let nav = UINavigationController(rootViewController: listVC)
        nav.navigationBar.prefersLargeTitles = true
        navigationController = nav
        window.rootViewController = nav
        window.makeKeyAndVisible()
    }
}

extension AppCoordinator: TripListRouter {
    func showCreateTrip(onUpdated: @escaping () -> Void) {
        let editor = TripEditorViewController()
        editor.completion = { onUpdated() }
        navigationController?.present(UINavigationController(rootViewController: editor), animated: true)
    }

    func showEditTrip(_ trip: Trip, onUpdated: @escaping () -> Void) {
        let editor = TripEditorViewController(trip: trip)
        editor.completion = { onUpdated() }
        navigationController?.present(UINavigationController(rootViewController: editor), animated: true)
    }

    func showPlaces(for trip: Trip) {
        let vc = PlaceListViewController(trip: trip)
        navigationController?.pushViewController(vc, animated: true)
    }
}
