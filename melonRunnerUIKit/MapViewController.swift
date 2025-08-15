//
//  MapViewController.swift
//  melonRunnerUIKit
//
//  Created by Kroshchenko Vlada on 11.08.2025.
//

import UIKit
import MapKit
import CoreLocation
import HealthKit

// Класс для кастомной аннотации пользователя
class UserAnnotation: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
        super.init()
    }
}

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    // UI элементы
    private let mapView = MKMapView()
    private let timeLabel = UILabel()
    private let distanceLabel = UILabel()
    private let caloriesLabel = UILabel()
    private let startButton = UIButton(type: .system)
    private let pauseContinueButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)

    // Логика
    private let locationManager = CLLocationManager()
    private let healthStore = HKHealthStore()
    private var startTime: Date?
    private var pauseTime: Date?
    private var accumulatedTime: TimeInterval = 0.0
    private var timer: Timer?
    private var calorieQuery: HKStatisticsCollectionQuery?
    private var locations: [CLLocation] = []
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    private var totalDistance: Double = 0.0
    private var calories: Double = 0.0
    private var isRunning: Bool = false
    private var isPaused: Bool = false
    private var userAnnotation: UserAnnotation?
    private var routeOverlay: MKPolyline?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocationManager()
        requestPermissions()
    }

    private func setupUI() {
        view.backgroundColor = .white

        // Настройка карты
        mapView.delegate = self
        mapView.mapType = .standard
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Метки
        let labelsStack = UIStackView(arrangedSubviews: [timeLabel, distanceLabel, caloriesLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 10
        labelsStack.alignment = .leading
        labelsStack.backgroundColor = .white.withAlphaComponent(0.9)
        labelsStack.layer.cornerRadius = 12
        labelsStack.layer.shadowRadius = 5
        labelsStack.layer.shadowOpacity = 0.5
        labelsStack.isOpaque = false
        labelsStack.layer.masksToBounds = false
        view.addSubview(labelsStack)
        labelsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            labelsStack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -100),
            labelsStack.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            labelsStack.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            labelsStack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20),
            labelsStack.widthAnchor.constraint(equalToConstant: 250)
        ])

        timeLabel.text = "⏱️ Время: 00:00:00"
        timeLabel.font = .systemFont(ofSize: 20, weight: .medium)
        timeLabel.textColor = .black
        timeLabel.textAlignment = .left

        distanceLabel.text = "👣 Дистанция: 0.00 км"
        distanceLabel.font = .systemFont(ofSize: 20, weight: .medium)
        distanceLabel.textColor = .black
        distanceLabel.textAlignment = .left

        caloriesLabel.text = "🔥 Калории: 0 ккал"
        caloriesLabel.font = .systemFont(ofSize: 20, weight: .medium)
        caloriesLabel.textColor = .black
        caloriesLabel.textAlignment = .left

        // Кнопка "Старт"
        startButton.setTitle("Старт", for: .normal)
        startButton.backgroundColor = .green
        startButton.setTitleColor(.white, for: .normal)
        startButton.layer.cornerRadius = 10
        startButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        startButton.addTarget(self, action: #selector(startRun), for: .touchUpInside)
        view.addSubview(startButton)
        startButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            startButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            startButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            startButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            startButton.heightAnchor.constraint(equalToConstant: 50)
        ])

        // Кнопка "Пауза"/"Продолжить"
        pauseContinueButton.setTitle("Пауза", for: .normal)
        pauseContinueButton.backgroundColor = .gray
        pauseContinueButton.setTitleColor(.white, for: .normal)
        pauseContinueButton.layer.cornerRadius = 10
        pauseContinueButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        pauseContinueButton.addTarget(self, action: #selector(pauseRun), for: .touchUpInside)
        view.addSubview(pauseContinueButton)
        pauseContinueButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            pauseContinueButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            pauseContinueButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            pauseContinueButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5, constant: -30),
            pauseContinueButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        pauseContinueButton.isHidden = true

        // Кнопка "Завершить"
        stopButton.setTitle("Завершить", for: .normal)
        stopButton.backgroundColor = .red
        stopButton.setTitleColor(.white, for: .normal)
        stopButton.layer.cornerRadius = 10
        stopButton.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        stopButton.addTarget(self, action: #selector(stopRun), for: .touchUpInside)
        view.addSubview(stopButton)
        stopButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stopButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            stopButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stopButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.5, constant: -30),
            stopButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        stopButton.isHidden = true
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
    }

    private func updateButtons() {
        startButton.isHidden = isRunning
        pauseContinueButton.isHidden = !isRunning
        stopButton.isHidden = !isRunning
        view.gestureRecognizers?.first(where: { $0 is UISwipeGestureRecognizer })?.isEnabled = !isRunning

        pauseContinueButton.setTitle(isPaused ? "Продолжить" : "Пауза", for: .normal)
        pauseContinueButton.backgroundColor = isPaused ? .green : .blue
    }

    @objc private func backPressed() {
        dismiss(animated: true, completion: nil)
    }

    @objc private func startRun() {
        isRunning = true
        isPaused = false
        startTime = Date()
        accumulatedTime = 0.0
        locations.removeAll()
        routeCoordinates.removeAll()
        totalDistance = 0.0
        calories = 0.0
        timeLabel.text = "⏱️ Время: 00:00:00"
        distanceLabel.text = "👣 Дистанция: 0.00 км"
        caloriesLabel.text = "🔥 Калории: 0 ккал"
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        startCalorieUpdates()
        updateButtons()
    }

    @objc private func pauseRun() {
        isPaused.toggle()
        if isPaused {
            timer?.invalidate()
            pauseTime = Date()
            locationManager.stopUpdatingLocation()
            // Не останавливаем calorieQuery, чтобы сохранить данные
        } else {
            guard let pauseTime = pauseTime else { return }
            accumulatedTime += pauseTime.timeIntervalSince(startTime ?? pauseTime)
            startTime = Date()
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
            locationManager.startUpdatingLocation()
            // Запрос калорий уже активен, не создаём новый
        }
        updateButtons()
    }

    @objc private func stopRun() {
        isRunning = false
        isPaused = false
        timer?.invalidate()
        stopCalorieUpdates()
        fetchCalories()
        mapView.removeOverlays(mapView.overlays)
        updateButtons()
    }

    @objc private func updateTimer() {
        guard let startTime = startTime else { return }
        let currentTime = accumulatedTime + Date().timeIntervalSince(startTime)
        let hours = Int(currentTime) / 3600
        let minutes = (Int(currentTime) % 3600) / 60
        let seconds = Int(currentTime) % 60
        timeLabel.text = String(format: "⏱️ Время: %02d:%02d:%02d", hours, minutes, seconds)
    }

    private func startCalorieUpdates() {
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        guard let startTime = startTime else { return }

        // Создаём новый запрос только если calorieQuery не существует
        if calorieQuery == nil {
            let predicate = HKQuery.predicateForSamples(withStart: startTime, end: nil, options: .strictStartDate)
            let query = HKStatisticsCollectionQuery(
                quantityType: energyType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum,
                anchorDate: startTime,
                intervalComponents: DateComponents(second: 10)
            )

            query.initialResultsHandler = { [weak self] query, collection, error in
                self?.updateCalories(from: collection)
            }

            query.statisticsUpdateHandler = { [weak self] query, statistics, collection, error in
                self?.updateCalories(from: collection)
            }

            healthStore.execute(query)
            calorieQuery = query
        }
    }

    private func updateCalories(from collection: HKStatisticsCollection?) {
        guard let collection = collection, let startTime = startTime else { return }
        let now = Date()
        var totalCalories: Double = self.calories // Сохраняем текущее значение
        collection.enumerateStatistics(from: startTime, to: now) { statistics, _ in
            if let sum = statistics.sumQuantity() {
                let newCalories = sum.doubleValue(for: HKUnit.kilocalorie())
                if newCalories > 0 { // Обновляем только при наличии новых данных
                    totalCalories = max(totalCalories, newCalories)
                }
            }
        }
        DispatchQueue.main.async { [weak self] in
            self?.calories = totalCalories
            self?.caloriesLabel.text = String(format: "🔥 Калории: %.0f ккал", totalCalories)
        }
    }

    private func stopCalorieUpdates() {
        if let query = calorieQuery {
            healthStore.stop(query)
            calorieQuery = nil
        }
    }

    private func fetchCalories() {
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let now = Date()
        let startOfRun = startTime ?? now
        let predicate = HKQuery.predicateForSamples(withStart: startOfRun, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            if let sum = result?.sumQuantity() {
                let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                DispatchQueue.main.async {
                    self?.calories = calories
                    self?.caloriesLabel.text = String(format: "🔥 Калории: %.0f ккал", calories)
                }
            }
        }
        healthStore.execute(query)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else { return }

        // Обновляем аннотацию пользователя
        DispatchQueue.main.async { [weak self] in
            if let annotation = self?.userAnnotation {
                annotation.coordinate = newLocation.coordinate
            } else {
                self?.userAnnotation = UserAnnotation(coordinate: newLocation.coordinate)
                if let annotation = self?.userAnnotation {
                    self?.mapView.addAnnotation(annotation)
                }
            }
        }

        // Обновляем маршрут и дистанцию только во время активной пробежки
        if isRunning && !isPaused {
            self.locations.append(newLocation)
            DispatchQueue.main.async { [weak self] in
                self?.routeCoordinates = self?.locations.map { $0.coordinate } ?? []

                // Обновление дистанции
                if let locations = self?.locations, locations.count > 1 {
                    let lastLocation = locations[locations.count - 2]
                    self?.totalDistance += newLocation.distance(from: lastLocation) / 1000
                    self?.distanceLabel.text = String(format: "👣 Дистанция: %.2f км", self?.totalDistance ?? 0 / 1000)
                }

                // Обновление маршрута на карте
                self?.updateRouteOverlay()
            }
        }

        // Обновление позиции камеры карты
        DispatchQueue.main.async { [weak self] in
            let region = MKCoordinateRegion(
                center: newLocation.coordinate,
                latitudinalMeters: 500,
                longitudinalMeters: 500
            )
            self?.mapView.setRegion(region, animated: true)
        }
    }

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is UserAnnotation {
            let identifier = "userAnnotation"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
            if view == nil {
                view = MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                let image = UIImage(systemName: "person.circle.fill")?.withTintColor(.yellow)
                view?.image = image
                view?.canShowCallout = false
            } else {
                view?.annotation = annotation
            }
            return view
        }
        return nil
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = .yellow
            renderer.lineWidth = 6.0
            return renderer
        }
        return MKOverlayRenderer()
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Ошибка геолокации: \(error.localizedDescription)")
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            locationManager.startUpdatingLocation()
        }
    }

    private func updateRouteOverlay() {
        if let overlay = routeOverlay {
            mapView.removeOverlay(overlay)
        }
        if routeCoordinates.count > 1 {
            routeOverlay = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
            mapView.addOverlay(routeOverlay!)
        }
    }

    private func requestPermissions() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        if CLLocationManager.locationServicesEnabled() {
            locationManager.startUpdatingLocation()
        }

        guard HKHealthStore.isHealthDataAvailable() else { return }
        let typesToRead: Set = [HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!]
        healthStore.requestAuthorization(toShare: nil, read: typesToRead) { success, error in
            if !success {
                print("Ошибка авторизации HealthKit: \(error?.localizedDescription ?? "Неизвестная ошибка")")
            }
        }
    }
}
