//
//  LocationManger.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/5/25.
//

import CoreLocation

import SwiftUI
import CoreLocation

enum LocationError: Error {
    case denied
    case restricted
    case unableToFindLocation
}

final class LocationManager: NSObject, ObservableObject {
    @Published var lastLocation: CLLocation?
    @Published var error: LocationError?

    private let shared = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?
    private var authContinuation: CheckedContinuation<Void, Error>?

    override init() {
        super.init()
        shared.delegate = self
        shared.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() async throws -> CLLocation {
        switch shared.authorizationStatus {
        case .notDetermined:
            shared.requestWhenInUseAuthorization()
            try await waitForAuthorization()
        case .restricted:
            throw LocationError.restricted
        case .denied:
            throw LocationError.denied
        default:
            break
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            shared.requestLocation()
        }
    }

    private func waitForAuthorization() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.authContinuation = continuation
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        Task { @MainActor in
            if [.authorizedWhenInUse, .authorizedAlways].contains(manager.authorizationStatus) {
                authContinuation?.resume(returning: ())
            } else if manager.authorizationStatus == .restricted {
                authContinuation?.resume(throwing: LocationError.restricted)
            } else if manager.authorizationStatus == .denied {
                authContinuation?.resume(throwing: LocationError.denied)
            }
            authContinuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task { @MainActor in
            if let location = locations.last {
                lastLocation = location
                continuation?.resume(returning: location)
            } else {
                continuation?.resume(throwing: LocationError.unableToFindLocation)
            }
            continuation = nil
        }
    }

    nonisolated func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task { @MainActor in
            continuation?.resume(throwing: error)
            continuation = nil
        }
    }
}
