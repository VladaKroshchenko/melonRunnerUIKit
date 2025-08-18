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

    // MARK: - Elements
    // UI элементы
    private let mapView = MKMapView()
    private let timeLabel = UILabel()
    private let distanceLabel = UILabel()
    private let caloriesLabel = UILabel()
    private let startButton = UIButton(type: .system)
    private let pauseContinueButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private let backButton = UIButton()

    // Логика
    private let locationManager = CLLocationManager()
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    private let healthStore = HKHealthStore()
    private var timer: Timer?
    private var calorieQuery: HKStatisticsCollectionQuery?
    private var userAnnotation: UserAnnotation?
    private var routeOverlay: MKPolyline?

    // Цвет фона (тёплый пастельно-оранжевый)
    let backgroundColor = UIColor(red: 0.98, green: 0.82, blue: 0.50, alpha: 1.0)

    // Цвет кожуры дыни (золотисто-жёлтый)
    let melonRind = UIColor(red: 0.96, green: 0.80, blue: 0.27, alpha: 1.0)

    // Цвет сетки кожуры (светло-жёлтый)
    let melonPattern = UIColor(red: 0.99, green: 0.91, blue: 0.64, alpha: 1.0)

    // Цвет ботвы и ног (тёмно-зелёный)
    let stemAndLegs = UIColor(red: 0.32, green: 0.50, blue: 0.29, alpha: 1.0)

    // Цвет шляпы (тёплый оранжевый)
    let hatColor = UIColor(red: 0.91, green: 0.60, blue: 0.23, alpha: 1.0)

    // Тёмно-коричневый для контуров и лица
    let outlineAndFace = UIColor(red: 0.31, green: 0.29, blue: 0.19, alpha: 1.0)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLocationManager()
        setupNavigationItem()
        requestPermissions()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restoreRunState()
    }

    // MARK: - Appearance

    private func setupUI() {
        view.backgroundColor = UIColor(red: 0.98, green: 0.82, blue: 0.50, alpha: 1.0)

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
        labelsStack.backgroundColor = UIColor(red: 0.99, green: 0.91, blue: 0.64, alpha: 1.0).withAlphaComponent(0.8)
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
        timeLabel.font = .systemFont(ofSize: 20, weight: .bold)
        timeLabel.textColor = .black
        timeLabel.textAlignment = .left

        distanceLabel.text = "👣 Дистанция: 0.00 км"
        distanceLabel.font = .systemFont(ofSize: 20, weight: .bold)
        distanceLabel.textColor = .black
        distanceLabel.textAlignment = .left

        caloriesLabel.text = "🔥 Калории: 0 ккал"
        caloriesLabel.font = .systemFont(ofSize: 20, weight: .bold)
        caloriesLabel.textColor = .black
        caloriesLabel.textAlignment = .left

        // Кнопка "Старт"
        startButton.setTitle("Старт", for: .normal)
        startButton.backgroundColor = UIColor(red: 0.32, green: 0.50, blue: 0.29, alpha: 1.0)
        startButton.setTitleColor(UIColor(red: 0.99, green: 0.91, blue: 0.64, alpha: 1.0), for: .normal)
        startButton.layer.cornerRadius = 10
        startButton.titleLabel?.font = .systemFont(ofSize: 25, weight: .bold)
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
        pauseContinueButton.setTitleColor(UIColor(red: 0.32, green: 0.50, blue: 0.29, alpha: 1.0), for: .normal)
        pauseContinueButton.layer.cornerRadius = 10
        pauseContinueButton.titleLabel?.font = .systemFont(ofSize: 23, weight: .bold)
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
        stopButton.backgroundColor = UIColor(red: 0.91, green: 0.60, blue: 0.23, alpha: 1.0).withAlphaComponent(0.8)
        stopButton.setTitleColor(UIColor(red: 0.32, green: 0.50, blue: 0.29, alpha: 1.0), for: .normal)
        stopButton.layer.cornerRadius = 10
        stopButton.titleLabel?.font = .systemFont(ofSize: 23, weight: .bold)
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

        // Кнопка "назад"
        let chevron = UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
        backButton.setImage(chevron, for: .normal)
        backButton.backgroundColor = .white
        backButton.alpha = 1
        backButton.layer.borderColor = UIColor.black.cgColor
        backButton.layer.borderWidth = 1
        backButton.setTitleColor(.black, for: .normal)
        backButton.tintColor = .black
        backButton.layer.cornerRadius = 12
        NSLayoutConstraint.activate([
            backButton.widthAnchor.constraint(equalToConstant: 32),
            backButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    private func setupNavigationItem() {
        backButton.addTarget(self, action: #selector(backPressed), for: .touchUpInside)
        let customBackButton = UIBarButtonItem(customView: backButton)
        navigationItem.leftBarButtonItem = customBackButton
    }

    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        locationManager.allowsBackgroundLocationUpdates = true

        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
    }

    private func updateButtons() {
        let runManager = RunManager.shared

        startButton.isHidden = runManager.isRunning
        pauseContinueButton.isHidden = !runManager.isRunning
        stopButton.isHidden = !runManager.isRunning
        view.gestureRecognizers?.first(where: { $0 is UISwipeGestureRecognizer })?.isEnabled = !runManager.isRunning

        pauseContinueButton.setTitle(runManager.isPaused ? "Продолжить" : "Пауза", for: .normal)
        pauseContinueButton.backgroundColor = runManager.isPaused ? UIColor(red: 0.96, green: 0.80, blue: 0.27, alpha: 1.0).withAlphaComponent(0.8) : UIColor(red: 0.99, green: 0.91, blue: 0.64, alpha: 1.0).withAlphaComponent(0.8)
    }

    private func updateUI() {
        let runManager = RunManager.shared

        // Обновляем метки времени, дистанции и калорий
        updateTimer()
        distanceLabel.text = String(format: "👣 Дистанция: %.2f км", runManager.totalDistance)
        caloriesLabel.text = String(format: "🔥 Калории: %.0f ккал", runManager.calories)

        // Обновляем кнопки в зависимости от состояния пробежки
        updateButtons()
    }


    // MARK: - Actions

    @objc private func backPressed() {
        // dismiss(animated: true, completion: nil) // Эта строка для закрытия карты если она открыта модалкой
        navigationController?.popViewController(animated: true)
    }

    @objc private func startRun() {
        let runManager = RunManager.shared

        runManager.isRunning = true
        runManager.isPaused = false
        runManager.startTime = Date()
        runManager.accumulatedTime = 0.0
        runManager.locations.removeAll()
        runManager.totalDistance = 0.0
        runManager.calories = 0.0
        timeLabel.text = "⏱️ Время: 00:00:00"
        distanceLabel.text = "👣 Дистанция: 0.00 км"
        caloriesLabel.text = "🔥 Калории: 0 ккал"
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
        startCalorieUpdates()
        updateButtons()
    }

    @objc private func pauseRun() {
        let runManager = RunManager.shared

        runManager.isPaused.toggle()
        if runManager.isPaused {
            timer?.invalidate()
            runManager.accumulatedTime += Date().timeIntervalSince(runManager.startTime ?? Date())
            locationManager.stopUpdatingLocation()
            // Не останавливаем calorieQuery, чтобы сохранить данные
        } else {
            runManager.startTime = Date()
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
            locationManager.startUpdatingLocation()
            // Запрос калорий уже активен, не создаём новый
        }
        updateButtons()
    }

    @objc private func stopRun() {
        let runManager = RunManager.shared

        runManager.isRunning = false
        runManager.isPaused = false
        timer?.invalidate()
        stopCalorieUpdates()
        fetchCalories()
        mapView.removeOverlays(mapView.overlays)
        updateButtons()
    }

    @objc private func updateTimer() {
        let runManager = RunManager.shared

        guard let startTime = runManager.startTime else {
            // Если startTime отсутствует, показываем только накопленное время
            let currentTime = runManager.accumulatedTime
            let hours = Int(currentTime) / 3600
            let minutes = (Int(currentTime) % 3600) / 60
            let seconds = Int(currentTime) % 60
            timeLabel.text = String(format: "⏱️ Время: %02d:%02d:%02d", hours, minutes, seconds)
            return
        }

        let currentTime: TimeInterval
        if runManager.isPaused || !runManager.isRunning {
            // Если пробежка на паузе или завершена, используем только накопленное время
            currentTime = runManager.accumulatedTime
        } else {
            // Если пробежка активна, добавляем время с момента старта
            currentTime = runManager.accumulatedTime + Date().timeIntervalSince(startTime)
        }

        let hours = Int(currentTime) / 3600
        let minutes = (Int(currentTime) % 3600) / 60
        let seconds = Int(currentTime) % 60
        timeLabel.text = String(format: "⏱️ Время: %02d:%02d:%02d", hours, minutes, seconds)
    }

    private func startCalorieUpdates() {
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        guard let startTime = RunManager.shared.startTime else { return }

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
        let runManager = RunManager.shared

        guard let collection = collection, let startTime = runManager.startTime else { return }
        let now = Date()
        var totalCalories: Double = runManager.calories // Сохраняем текущее значение
        collection.enumerateStatistics(from: startTime, to: now) { statistics, _ in
            if let sum = statistics.sumQuantity() {
                let newCalories = sum.doubleValue(for: HKUnit.kilocalorie())
                if newCalories > 0 { // Обновляем только при наличии новых данных
                    totalCalories = max(totalCalories, newCalories)
                }
            }
        }
        DispatchQueue.main.async { [weak self] in
            runManager.calories = totalCalories
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
        let startOfRun = RunManager.shared.startTime ?? now
        let predicate = HKQuery.predicateForSamples(withStart: startOfRun, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            if let sum = result?.sumQuantity() {
                let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                DispatchQueue.main.async {
                    RunManager.shared.calories = calories
                    self?.caloriesLabel.text = String(format: "🔥 Калории: %.0f ккал", calories)
                }
            }
        }
        healthStore.execute(query)
    }

    private func restoreRunState() {
        let runManager = RunManager.shared

        // Восстанавливаем состояние UI на основе текущего состояния пробежки
        if runManager.isRunning {
            // Запускаем таймер, если пробежка активна
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)

            // Если пробежка не на паузе, продолжаем обновлять местоположение
            if !runManager.isPaused {
                locationManager.startUpdatingLocation()
            }
        }

        // Обновляем UI
        updateUI()
    }

    //MARK: - Map & Location logic

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
            let runManager = RunManager.shared
        if runManager.isRunning && !runManager.isPaused {
            runManager.locations.append(newLocation)
            DispatchQueue.main.async { [weak self] in
                self?.routeCoordinates = runManager.locations.map { $0.coordinate } // Если при перезаходе потеряется черкаш, искать его тут скорее всего

                // Обновление дистанции
                if runManager.locations.count > 1 {
                    let lastLocation = runManager.locations[runManager.locations.count - 2]
                    runManager.totalDistance += newLocation.distance(from: lastLocation) / 1000
                    self?.distanceLabel.text = String(format: "👣 Дистанция: %.2f км", runManager.totalDistance)
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

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor(red: 0.32, green: 0.50, blue: 0.29, alpha: 1.0)
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

    //MARK: - Permissons

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
