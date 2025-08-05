//
//  LocationManger.swift
//  Wellnest
//
//  Created by Heejung Yang on 8/5/25.
//

import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()

    @Published var location: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus?

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization() // 앱 사용 중 위치 권한 요청
        manager.startUpdatingLocation() // 위치 업데이트 시작
    }

    // 권한 변경 시 호출
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    // 위치 업데이트 시 호출
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
    }

    // 에러 처리
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("위치 가져오기 실패: \(error.localizedDescription)")
    }
}
