//
//  LocationManager.swift
//  melonRunnerUIKit
//
//  Created by Emelyanov Artem on 26.08.2025.
//

import CoreLocation
import Combine

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private var locationManager = CLLocationManager()
    @Published var location: CLLocation?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        location = locations.first
        locationManager.stopUpdatingLocation() // Остановите обновления для экономии заряда батареи
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Не удалось определить местоположение пользователя: \(error.localizedDescription)")
    }
}
