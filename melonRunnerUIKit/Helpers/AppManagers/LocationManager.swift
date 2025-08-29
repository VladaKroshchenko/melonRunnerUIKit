//
//  LocationManager.swift
//  melonRunnerUIKit
//
//  Created by Emelyanov Artem on 26.08.2025.
//

import CoreLocation
import Combine

import CoreLocation

class LocationManager: NSObject, CLLocationManagerDelegate {
    static let shared = LocationManager()
    private var locationManager = CLLocationManager()

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        requestPermissions()
    }

    private func requestPermissions() {
        locationManager.requestWhenInUseAuthorization()
    }

    // Публичный метод для начала обновления местоположения
    func startUpdatingLocation() {
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }
    }

    // Публичный метод для остановки обновления местоположения
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        // Отправка уведомления с новым местоположением
        NotificationCenter.default.post(name: .locationDidUpdate, object: nil, userInfo: ["location": newLocation])
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Ошибка геолокации: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            startUpdatingLocation()
        case .denied, .restricted:
            // Обработка случаев, когда доступ запрещен
            print("Доступ к местоположению запрещен")
        case .notDetermined:
            // Если статус не определен, ничего не делаем
            break
        @unknown default:
            break
        }
    }
}

extension Notification.Name {
    static let locationDidUpdate = Notification.Name("locationDidUpdate")
}

