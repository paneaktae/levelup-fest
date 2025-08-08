//  TripListRouter.swift
//  My Travel
//
//  Routing protocol for Trip list flows handled by Coordinator.

import Foundation

protocol TripListRouter: AnyObject {
    func showCreateTrip(onUpdated: @escaping () -> Void)
    func showEditTrip(_ trip: Trip, onUpdated: @escaping () -> Void)
    func showPlaces(for trip: Trip)
}
