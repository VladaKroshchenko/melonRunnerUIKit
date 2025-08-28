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
    private let runningTimeLabel = UILabel()
    private let timeLabel = UILabel()
    private let distanceNumberLabel = UILabel()
    private let distanceUnitLabel = UILabel()
    private let caloriesNumberLabel = UILabel()
    private let caloriesUnitLabel = UILabel()
    private let speedNumberLabel = UILabel()
    private let speedUnitLabel = UILabel()
    private let startButton = UIButton(type: .system)
    private let pauseContinueButton = UIButton(type: .system)
    private let stopButton = UIButton(type: .system)
    private let backButton = UIButton()
    private var buttonsStack: UIStackView!

    // Логика
    private let locationManager = CLLocationManager()
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    private let healthStore = HKHealthStore()
    private var timer: Timer?
    private var calorieQuery: HKStatisticsCollectionQuery?
    private var userAnnotation: UserAnnotation?
    private var routeOverlay: MKPolyline?

    let runTimer = RunTimer.shared
    let runManager = RunManager.shared

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

    private let decimalFormatter = NumberFormatter()
    private let integerFormatter = NumberFormatter()

    override func viewDidLoad() {
        super.viewDidLoad()
        decimalFormatter.locale = Locale(identifier: "ru_RU")
        decimalFormatter.numberStyle = .decimal
        decimalFormatter.minimumFractionDigits = 1
        decimalFormatter.maximumFractionDigits = 1
        integerFormatter.locale = Locale(identifier: "ru_RU")
        integerFormatter.numberStyle = .decimal
        integerFormatter.minimumFractionDigits = 0
        integerFormatter.maximumFractionDigits = 0
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

        // Плашка со статистикой с фиксированной шириной
        let statsView = UIView()
        statsView.backgroundColor = .white.withAlphaComponent(1)
        statsView.layer.cornerRadius = 12
        statsView.layer.shadowRadius = 5
        statsView.layer.shadowOpacity = 0.5
        statsView.layer.shadowColor = UIColor.black.cgColor
        statsView.layer.shadowOffset = .zero
        statsView.layer.masksToBounds = false
        view.addSubview(statsView)
        statsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            statsView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            statsView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            statsView.widthAnchor.constraint(equalToConstant: 300),
            statsView.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 20),
            statsView.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])

        let verticalStack = UIStackView()
        verticalStack.axis = .vertical
        verticalStack.spacing = 5
        verticalStack.alignment = .fill
        statsView.addSubview(verticalStack)
        verticalStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            verticalStack.topAnchor.constraint(equalTo: statsView.topAnchor, constant: 10),
            verticalStack.bottomAnchor.constraint(equalTo: statsView.bottomAnchor, constant: -10),
            verticalStack.leadingAnchor.constraint(equalTo: statsView.leadingAnchor, constant: 15),
            verticalStack.trailingAnchor.constraint(equalTo: statsView.trailingAnchor, constant: -15)
        ])

        runningTimeLabel.text = "Время пробежки"
        runningTimeLabel.font = .systemFont(ofSize: 14, weight: .medium)
        runningTimeLabel.textColor = .black.withAlphaComponent(0.7)
        verticalStack.addArrangedSubview(runningTimeLabel)

        let timeRow = UIStackView()
        timeRow.axis = .horizontal
        timeRow.alignment = .center
        timeRow.spacing = 5
        timeRow.distribution = .fill
        verticalStack.addArrangedSubview(timeRow)

        timeLabel.text = "00:00:00"
        timeLabel.font = .systemFont(ofSize: 28, weight: .bold)
        timeLabel.textColor = .black
        timeLabel.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        timeRow.addArrangedSubview(timeLabel)

        let buttonSpacer = UIView()
        buttonSpacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        timeRow.addArrangedSubview(buttonSpacer)

        buttonsStack = UIStackView()
        buttonsStack.axis = .horizontal
        buttonsStack.spacing = 10
        buttonsStack.translatesAutoresizingMaskIntoConstraints = false
        timeRow.addArrangedSubview(buttonsStack)

        NSLayoutConstraint.activate([
            buttonsStack.centerYAnchor.constraint(equalTo: timeLabel.centerYAnchor, constant: -5),
            buttonsStack.trailingAnchor.constraint(equalTo: timeRow.trailingAnchor)
        ])

        let statsRow = UIStackView()
        statsRow.axis = .horizontal
        statsRow.distribution = .fillEqually
        statsRow.spacing = 10
        verticalStack.addArrangedSubview(statsRow)

        // Distance stat
        let distanceStat = UIStackView()
        distanceStat.axis = .horizontal
        distanceStat.spacing = 5
        distanceStat.alignment = .leading
        let distIcon = UILabel()
        distIcon.text = "🏃🏻‍➡️"
        distIcon.font = .systemFont(ofSize: 20)
        distanceStat.addArrangedSubview(distIcon)
        let distValueStack = UIStackView()
        distValueStack.axis = .vertical
        distValueStack.spacing = 0
        distValueStack.alignment = .leading
        distanceNumberLabel.text = "0,0"
        distanceNumberLabel.font = .monospacedDigitSystemFont(ofSize: 21, weight: .bold)
        distanceNumberLabel.textColor = .black
        distValueStack.addArrangedSubview(distanceNumberLabel)
        distanceUnitLabel.text = "км"
        distanceUnitLabel.font = .systemFont(ofSize: 12, weight: .regular)
        distanceUnitLabel.textColor = .darkGray
        distValueStack.addArrangedSubview(distanceUnitLabel)
        distanceStat.addArrangedSubview(distValueStack)
        statsRow.addArrangedSubview(distanceStat)

        // Calories stat
        let caloriesStat = UIStackView()
        caloriesStat.axis = .horizontal
        caloriesStat.spacing = 5
        caloriesStat.alignment = .leading
        let calIcon = UILabel()
        calIcon.text = "🔥"
        calIcon.font = .systemFont(ofSize: 20)
        caloriesStat.addArrangedSubview(calIcon)
        let calValueStack = UIStackView()
        calValueStack.axis = .vertical
        calValueStack.spacing = 0
        calValueStack.alignment = .leading
        caloriesNumberLabel.text = "0"
        caloriesNumberLabel.font = .monospacedDigitSystemFont(ofSize: 21, weight: .bold)
        caloriesNumberLabel.textColor = .black
        calValueStack.addArrangedSubview(caloriesNumberLabel)
        caloriesUnitLabel.text = "ккал"
        caloriesUnitLabel.font = .systemFont(ofSize: 12, weight: .regular)
        caloriesUnitLabel.textColor = .darkGray
        calValueStack.addArrangedSubview(caloriesUnitLabel)
        caloriesStat.addArrangedSubview(calValueStack)
        statsRow.addArrangedSubview(caloriesStat)

        // Speed stat
        let speedStat = UIStackView()
        speedStat.axis = .horizontal
        speedStat.spacing = 5
        speedStat.alignment = .leading
        let speedIcon = UILabel()
        speedIcon.text = "⚡"
        speedIcon.font = .systemFont(ofSize: 20)
        speedStat.addArrangedSubview(speedIcon)
        let speedValueStack = UIStackView()
        speedValueStack.axis = .vertical
        speedValueStack.spacing = 0
        speedValueStack.alignment = .leading
        speedNumberLabel.text = "0,0"
        speedNumberLabel.font = .monospacedDigitSystemFont(ofSize: 21, weight: .bold)
        speedNumberLabel.textColor = .black
        speedValueStack.addArrangedSubview(speedNumberLabel)
        speedUnitLabel.text = "км/ч"
        speedUnitLabel.font = .systemFont(ofSize: 12, weight: .regular)
        speedUnitLabel.textColor = .darkGray
        speedValueStack.addArrangedSubview(speedUnitLabel)
        speedStat.addArrangedSubview(speedValueStack)
        statsRow.addArrangedSubview(speedStat)

        // Настройка кнопок
        startButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
        startButton.tintColor = stemAndLegs
        startButton.backgroundColor = UIColor.MenuButton.button
        startButton.layer.shadowRadius = 5
        startButton.layer.shadowOpacity = 0.5
        startButton.layer.shadowColor = UIColor.black.cgColor
        startButton.layer.shadowOffset = .zero
        startButton.layer.cornerRadius = 10
        startButton.setTitle(nil, for: .normal)
        startButton.addTarget(self, action: #selector(startRun), for: .touchUpInside)
        startButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        startButton.heightAnchor.constraint(equalToConstant: 40).isActive = true

        pauseContinueButton.tintColor = stemAndLegs
        pauseContinueButton.layer.cornerRadius = 10
        pauseContinueButton.layer.shadowRadius = 5
        pauseContinueButton.layer.shadowOpacity = 0.5
        pauseContinueButton.layer.shadowColor = UIColor.black.cgColor
        pauseContinueButton.layer.shadowOffset = .zero
        pauseContinueButton.setTitle(nil, for: .normal)
        pauseContinueButton.addTarget(self, action: #selector(pauseRun), for: .touchUpInside)
        pauseContinueButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        pauseContinueButton.heightAnchor.constraint(equalToConstant: 40).isActive = true

        stopButton.setImage(UIImage(systemName: "stop.fill"), for: .normal)
        stopButton.tintColor = stemAndLegs
        stopButton.layer.shadowRadius = 5
        stopButton.layer.shadowOpacity = 0.5
        stopButton.layer.shadowColor = UIColor.black.cgColor
        stopButton.layer.shadowOffset = .zero
        stopButton.backgroundColor = UIColor.MenuButton.circle
        stopButton.layer.cornerRadius = 10
        stopButton.setTitle(nil, for: .normal)
        stopButton.addTarget(self, action: #selector(stopRun), for: .touchUpInside)
        stopButton.widthAnchor.constraint(equalToConstant: 40).isActive = true
        stopButton.heightAnchor.constraint(equalToConstant: 40).isActive = true

        // Кнопка "назад"
        let chevron = UIImage(systemName: "chevron.backward", withConfiguration: UIImage.SymbolConfiguration(weight: .bold))
        backButton.setImage(chevron, for: .normal)
        backButton.backgroundColor = .white
        backButton.alpha = 1
        backButton.layer.shadowRadius = 5
        backButton.layer.shadowOpacity = 0.5
        backButton.layer.shadowColor = UIColor.black.cgColor
        backButton.layer.shadowOffset = .zero
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
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
    }

    private func updateButtons() {
        buttonsStack.arrangedSubviews.forEach { buttonsStack.removeArrangedSubview($0); $0.isHidden = true }

        if runManager.isRunning {
            stopButton.isHidden = false
            pauseContinueButton.isHidden = false
            buttonsStack.addArrangedSubview(stopButton)
            buttonsStack.addArrangedSubview(pauseContinueButton)
            if runManager.isPaused {
                pauseContinueButton.setImage(UIImage(systemName: "play.fill"), for: .normal)
                pauseContinueButton.backgroundColor = UIColor.MenuButton.button
            } else {
                pauseContinueButton.setImage(UIImage(systemName: "pause.fill"), for: .normal)
                pauseContinueButton.backgroundColor = .lightGray
            }
            startButton.isHidden = true
        } else {
            startButton.isHidden = false
            buttonsStack.addArrangedSubview(startButton)
            pauseContinueButton.isHidden = true
            stopButton.isHidden = true
        }

        view.gestureRecognizers?.first(where: { $0 is UISwipeGestureRecognizer })?.isEnabled = !runManager.isRunning
    }

    private func updateUI() {
        // Обновляем метки времени, дистанции и калорий
        updateLabels()
        distanceNumberLabel.text = decimalFormatter.string(from: NSNumber(value: runManager.totalDistance)) ?? "0,0"
        caloriesNumberLabel.text = integerFormatter.string(from: NSNumber(value: runManager.calories)) ?? "0"

        // Обновляем кнопки в зависимости от состояния пробежки
        updateButtons()
    }

    // MARK: - Actions

    @objc private func backPressed() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func startRun() {
        runManager.isRunning = true
        runManager.isPaused = false
        runManager.locations.removeAll()
        runManager.totalDistance = 0.0
        runManager.calories = 0.0
        runTimer.startTimer()
        timeLabel.text = "00:00:00"
        distanceNumberLabel.text = decimalFormatter.string(from: NSNumber(value: 0.0)) ?? "0,0"
        caloriesNumberLabel.text = integerFormatter.string(from: NSNumber(value: 0.0)) ?? "0"
        speedNumberLabel.text = decimalFormatter.string(from: NSNumber(value: 0.0)) ?? "0,0"
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateLabels), userInfo: nil, repeats: true)
        startCalorieUpdates()
        updateButtons()
    }

    @objc private func pauseRun() {
        runManager.isPaused.toggle()
        if runManager.isPaused {
            runTimer.pauseTimer()
            timer?.invalidate()
            locationManager.stopUpdatingLocation()
            speedNumberLabel.text = "0,0"
        } else {
            runTimer.startTimer()
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateLabels), userInfo: nil, repeats: true)
            locationManager.startUpdatingLocation()
        }
        updateButtons()
    }

    @objc private func stopRun() {
        runTimer.stopTimer()

        runManager.isRunning = false
        runManager.isPaused = false
        timer?.invalidate()
        stopCalorieUpdates()
        fetchCalories()
        mapView.removeOverlays(mapView.overlays)
        speedNumberLabel.text = "0,0"
        updateButtons()
    }

    @objc private func updateLabels() {
        timeLabel.text = String(formatTime(from: runTimer.totalTime))
    }

    private func startCalorieUpdates() {
        guard let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        guard let startTime = runTimer.startTime else { return }

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
        guard let collection = collection, let startTime = runTimer.startTime else { return }
        let now = Date()
        var totalCalories: Double = runManager.calories
        collection.enumerateStatistics(from: startTime, to: now) { statistics, _ in
            if let sum = statistics.sumQuantity() {
                let newCalories = sum.doubleValue(for: HKUnit.kilocalorie())
                if newCalories > 0 {
                    totalCalories = max(totalCalories, newCalories)
                }
            }
        }
        DispatchQueue.main.async { [weak self] in
            let runManager = RunManager.shared
            runManager.calories = totalCalories
            self?.caloriesNumberLabel.text = self?.integerFormatter.string(from: NSNumber(value: totalCalories)) ?? "0"
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
        let startOfRun = runTimer.startTime ?? now
        let predicate = HKQuery.predicateForSamples(withStart: startOfRun, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: energyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            if let sum = result?.sumQuantity() {
                let calories = sum.doubleValue(for: HKUnit.kilocalorie())
                DispatchQueue.main.async {
                    RunManager.shared.calories = calories
                    self?.caloriesNumberLabel.text = self?.integerFormatter.string(from: NSNumber(value: calories)) ?? "0"
                }
            }
        }
        healthStore.execute(query)
    }

    private func restoreRunState() {
        // Восстанавливаем состояние UI на основе текущего состояния пробежки
        if runManager.isRunning {
            // Запускаем таймер, если пробежка активна
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateLabels), userInfo: nil, repeats: true)

            // Если пробежка не на паузе, продолжаем обновлять местоположение
            if !runManager.isPaused {
                locationManager.startUpdatingLocation()
            } else {
                speedNumberLabel.text = "0,0"
            }
        }

        updateUI()
    }

    // MARK: - Map & Location Logic

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
                self?.routeCoordinates = runManager.locations.map { $0.coordinate }

                // Обновление дистанции
                if runManager.locations.count > 1 {
                    let lastLocation = runManager.locations[runManager.locations.count - 2]
                    runManager.totalDistance += newLocation.distance(from: lastLocation) / 1000
                    self?.distanceNumberLabel.text = self?.decimalFormatter.string(from: NSNumber(value: runManager.totalDistance)) ?? "0,0"
                }

                // Обновление скорости на основе данных CLLocation
                let speed = newLocation.speed >= 0 ? newLocation.speed * 3.6 : 0.0 // Convert m/s to km/h
                self?.speedNumberLabel.text = self?.decimalFormatter.string(from: NSNumber(value: speed)) ?? "0,0"

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

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        guard annotation is MKUserLocation else {
            return nil
        }

        let id = "UserLocationView"
        let view = mapView.dequeueReusableAnnotationView(withIdentifier: id) ?? MKAnnotationView(annotation: annotation, reuseIdentifier: id)
        view.annotation = annotation
        view.canShowCallout = false

        let image = UIImage(named: "userAnnotation")?.withTintColor(.black)
        view.image = image

        if view.layer.animation(forKey: "pulse") == nil {
            let pulse = CABasicAnimation(keyPath: "transform.scale")
            pulse.fromValue = 0.95
            pulse.toValue = 1.05
            pulse.duration = 1.2
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            view.layer.add(pulse, forKey: "pulse")
        }

        return view
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

    // MARK: - Permissions

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
