//
//  LocationManger.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/5/25.
//

import CoreLocation

class LocationManager: NSObject, ObservableObject {
    private let shared = CLLocationManager()

    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?

    override init() {
        super.init()
        shared.delegate = self
        shared.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        shared.requestWhenInUseAuthorization() // 앱 사용 중 위치 권한 요청
        shared.startUpdatingLocation() // 위치 업데이트 시작
    }

    // 권한 변경 시 호출
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }
}

extension LocationManager: CLLocationManagerDelegate {

    // 위치 업데이트 시 호출
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }

    // 에러 처리
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 가져오기 실패: \(error.localizedDescription)")
    }
}
