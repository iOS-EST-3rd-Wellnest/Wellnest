//
//  LocationManger.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/5/25.
//

import CoreLocation

enum LocationError: Error {
    case denied
    case restricted
    case unableToFindLocation
}

final class LocationManager: NSObject {
    private let shared = CLLocationManager()
    private var continuation: CheckedContinuation<CLLocation, Error>?

    override init() {
        super.init()
        shared.delegate = self
        shared.desiredAccuracy = kCLLocationAccuracyBest
    }

    /// 비동기 현재 위치 요청
    func requestLocation() async throws -> CLLocation {
        // 권한 체크
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

    /// 권한 요청 대기
    private func waitForAuthorization() async throws {
        try await withCheckedThrowingContinuation { continuation in
            self.authContinuation = continuation
        }
    }

    private var authContinuation: CheckedContinuation<Void, Error>?
}

extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if [.authorizedWhenInUse, .authorizedAlways].contains(manager.authorizationStatus) {
            authContinuation?.resume(returning: ())
            authContinuation = nil
        } else if shared.authorizationStatus == .denied {
            authContinuation?.resume(throwing: LocationError.denied)
            authContinuation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            continuation?.resume(returning: location)
            continuation = nil
        } else {
            continuation?.resume(throwing: LocationError.unableToFindLocation)
            continuation = nil
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        continuation?.resume(throwing: error)
        continuation = nil
    }
}
