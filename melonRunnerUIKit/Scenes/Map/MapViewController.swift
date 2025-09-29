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

class MapViewController: UIViewController, MKMapViewDelegate {

    // UI элементы
    private var mapView = MKMapView()
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
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    private var allRouteCoordinates: [CLLocationCoordinate2D] = [] // Для хранения всех координат маршрута
    private var timer: Timer?
    private var userAnnotation: UserAnnotation?
    private var routeOverlay: MKPolyline?
    private var recenterTimer: Timer?
    private var isProgrammaticRegionChange: Bool = false
    private var hasInitialCentered: Bool = false
    private var routeTimer: Timer?
    private var lastLocation: CLLocation?
    private var workoutStartDate: Date?

    let runTimer = RunTimer.shared
    let runManager = RunManager.shared

    // Ключи для UserDefaults
    private let userDefaults = UserDefaults.standard
    private let routeCoordinatesKey = "RouteCoordinates"
    private let totalDistanceKey = "TotalDistance"
    private let caloriesKey = "Calories"
    private let workoutStartDateKey = "WorkoutStartDate"

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

        NotificationCenter.default.addObserver(self, selector: #selector(locationDidUpdate(_:)), name: .locationDidUpdate, object: nil)

        decimalFormatter.locale = Locale(identifier: "ru_RU")
        decimalFormatter.numberStyle = .decimal
        decimalFormatter.minimumFractionDigits = 1
        decimalFormatter.maximumFractionDigits = 1
        integerFormatter.locale = Locale(identifier: "ru_RU")
        integerFormatter.numberStyle = .decimal
        integerFormatter.minimumFractionDigits = 0
        integerFormatter.maximumFractionDigits = 0

        setupUI()
        setupNavigationItem()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        restoreRunState()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Сохраняем данные пробежки в UserDefaults
        saveRunState()
    }

    // MARK: - Appearance

    private func setupUI() {
        view.backgroundColor = backgroundColor

        // Настройка карты
        mapView = MKMapView(frame: view.bounds)
        mapView.delegate = self
        mapView.mapType = .standard
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.isZoomEnabled = true
        mapView.isScrollEnabled = true
        view.addSubview(mapView)
        mapView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: view.topAnchor),
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        // Плашка со статистикой
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
        distanceNumberLabel.adjustsFontSizeToFitWidth = true
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
        caloriesNumberLabel.adjustsFontSizeToFitWidth = true
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
        speedNumberLabel.adjustsFontSizeToFitWidth = true
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
        updateLabels()
        distanceNumberLabel.text = decimalFormatter.string(from: NSNumber(value: runManager.totalDistance)) ?? "0,0"
        caloriesNumberLabel.text = integerFormatter.string(from: NSNumber(value: runManager.calories)) ?? "0"
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
        allRouteCoordinates.removeAll() // Очищаем все координаты маршрута
        runManager.totalDistance = 0.0
        runManager.calories = 0.0
        runTimer.startTimer()
        workoutStartDate = Date()
        timeLabel.text = "00:00:00"
        distanceNumberLabel.text = decimalFormatter.string(from: NSNumber(value: 0.0)) ?? "0,0"
        caloriesNumberLabel.text = integerFormatter.string(from: NSNumber(value: 0.0)) ?? "0"
        speedNumberLabel.text = decimalFormatter.string(from: NSNumber(value: 0.0)) ?? "0,0"
        timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateLabels), userInfo: nil, repeats: true)
        HealthKitManager.shared.startWorkout()
        routeTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(savePartialRoute), userInfo: nil, repeats: true)
        lastLocation = nil
        updateButtons()
        updateRouteOverlay() // Обновляем маршрут, чтобы очистить старую линию
        // Очищаем сохраненные данные в UserDefaults
        clearSavedRunState()
    }

    @objc private func pauseRun() {
        runManager.isPaused.toggle()
        if runManager.isPaused {
            runTimer.pauseTimer()
            timer?.invalidate()
            routeTimer?.invalidate()
            speedNumberLabel.text = "0,0"
            savePartialRoute() // Сохраняем текущий сегмент маршрута
            HealthKitManager.shared.pauseWorkout()
        } else {
            runTimer.startTimer()
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateLabels), userInfo: nil, repeats: true)
            routeTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(savePartialRoute), userInfo: nil, repeats: true)
            HealthKitManager.shared.resumeWorkout()
        }
        updateButtons()
    }

    @objc private func stopRun() {
        runTimer.stopTimer()
        runManager.isRunning = false
        runManager.isPaused = false
        timer?.invalidate()
        routeTimer?.invalidate()
        routeTimer = nil
        speedNumberLabel.text = "0,0"
        updateButtons()
        saveWorkout()
        // Очищаем сохраненные данные в UserDefaults
        clearSavedRunState()
    }

    @objc private func updateLabels() {
        timeLabel.text = String(formatTime(from: runTimer.totalTime))
    }

    @objc private func savePartialRoute() {
        HealthKitManager.shared.savePartialRoute(locations: runManager.locations) { [weak self] success in
            if success {
                self?.runManager.locations.removeAll() // Очищаем локации для HealthKit
            }
        }
    }

private func saveWorkout() {
        guard let startDate = workoutStartDate else {
            return
        }
        let endDate = Date()
        
        HealthKitManager.shared.saveWorkout(
            startDate: startDate,
            endDate: endDate,
            duration: runTimer.totalTime,
            calories: runManager.calories,
            distance: runManager.totalDistance,
            locations: runManager.locations
        ) { [weak self] success in
            if !success {
                print("Ошибка сохранения тренировки в HealthKit")
            }
            self?.resetWorkout()
        }
    }

    private func resetWorkout() {
        // Reset local variables
    }

    private func saveRunState() {
        // Сохраняем координаты маршрута
        let coordinatesData = allRouteCoordinates.map { ["latitude": $0.latitude, "longitude": $0.longitude] }
        userDefaults.set(coordinatesData, forKey: routeCoordinatesKey)
        // Сохраняем дистанцию и калории
        userDefaults.set(runManager.totalDistance, forKey: totalDistanceKey)
        userDefaults.set(runManager.calories, forKey: caloriesKey)
        // Сохраняем дату начала пробежки
        userDefaults.set(workoutStartDate, forKey: workoutStartDateKey)
    }

    private func clearSavedRunState() {
        userDefaults.removeObject(forKey: routeCoordinatesKey)
        userDefaults.removeObject(forKey: totalDistanceKey)
        userDefaults.removeObject(forKey: caloriesKey)
        userDefaults.removeObject(forKey: workoutStartDateKey)
    }

    private func restoreRunState() {
        if runManager.isRunning {
            // Запускаем таймер, если пробежка активна
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateLabels), userInfo: nil, repeats: true)
            if !runManager.isPaused {
                routeTimer = Timer.scheduledTimer(timeInterval: 60.0, target: self, selector: #selector(savePartialRoute), userInfo: nil, repeats: true)
                LocationManager.shared.startUpdatingLocation()
            } else {
                speedNumberLabel.text = "0,0"
            }
        }

        // Восстанавливаем координаты маршрута из UserDefaults
        if let coordinatesData = userDefaults.array(forKey: routeCoordinatesKey) as? [[String: Double]] {
            allRouteCoordinates = coordinatesData.map { CLLocationCoordinate2D(latitude: $0["latitude"]!, longitude: $0["longitude"]!) }
        }

        // Восстанавливаем дистанцию и калории
        runManager.totalDistance = userDefaults.double(forKey: totalDistanceKey)
        runManager.calories = userDefaults.double(forKey: caloriesKey)
        workoutStartDate = userDefaults.object(forKey: workoutStartDateKey) as? Date

        // Явно обновляем все метки и маршрут
        timeLabel.text = String(formatTime(from: runTimer.totalTime))
        distanceNumberLabel.text = decimalFormatter.string(from: NSNumber(value: runManager.totalDistance)) ?? "0,0"
        caloriesNumberLabel.text = integerFormatter.string(from: NSNumber(value: runManager.calories)) ?? "0"
        updateButtons()
        updateRouteOverlay() // Восстанавливаем линию маршрута
    }

    // MARK: - Map & Location Logic

    @objc private func locationDidUpdate(_ notification: Notification) {
        guard let newLocation = notification.userInfo?["location"] as? CLLocation else { return }

        if runManager.isRunning && !runManager.isPaused {
            runManager.locations.append(newLocation)
            allRouteCoordinates.append(newLocation.coordinate)
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.routeCoordinates = self.allRouteCoordinates

                // Обновление дистанции и калорий
                if let lastLocation = self.lastLocation {
                    let deltaDistance = newLocation.distance(from: lastLocation)
                    runManager.totalDistance += deltaDistance / 1000
                    self.distanceNumberLabel.text = self.decimalFormatter.string(from: NSNumber(value: runManager.totalDistance)) ?? "0,0"

                    // Расчет калорий
                    let deltaKm = deltaDistance / 1000
                    let deltaCalories = deltaKm * HealthKitManager.shared.currentUserWeight * 1.0 // Примерная формула
                    runManager.calories += deltaCalories
                    self.caloriesNumberLabel.text = self.integerFormatter.string(from: NSNumber(value: runManager.calories)) ?? "0"

                    // Сохранение дистанции
                    HealthKitManager.shared.saveDistanceSample(
                        distance: deltaDistance,
                        startTime: lastLocation.timestamp,
                        endTime: newLocation.timestamp
                    ) { success in
                        if !success {
                            print("Ошибка сохранения дистанции")
                        }
                    }
                    
                    // Сохранение калорий
                    HealthKitManager.shared.saveCaloriesSample(
                        calories: deltaCalories,
                        startTime: lastLocation.timestamp,
                        endTime: newLocation.timestamp
                    ) { success in
                        if !success {
                            print("Ошибка сохранения калорий")
                        }
                    }
                }

                // Обновление скорости
                let speed = newLocation.speed >= 0 ? newLocation.speed * 3.6 : 0.0
                self.speedNumberLabel.text = self.decimalFormatter.string(from: NSNumber(value: speed)) ?? "0,0"

                self.updateRouteOverlay()
                self.lastLocation = newLocation
                // Сохраняем состояние после обновления
                self.saveRunState()
            }
        }

        // Обновление позиции камеры карты
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if self.recenterTimer == nil {
                self.isProgrammaticRegionChange = true
                if !self.hasInitialCentered {
                    let region = MKCoordinateRegion(
                        center: newLocation.coordinate,
                        latitudinalMeters: 500,
                        longitudinalMeters: 500
                    )
                    self.mapView.setRegion(region, animated: false)
                    self.hasInitialCentered = true
                } else {
                    self.mapView.setCenter(newLocation.coordinate, animated: true)
                }
                self.isProgrammaticRegionChange = false
            }
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

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if isProgrammaticRegionChange {
            return
        }

        recenterTimer?.invalidate()
        recenterTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            self?.recenterToCurrentLocation()
        }
    }

    private func recenterToCurrentLocation() {
        mapView.setUserTrackingMode(.follow, animated: true)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
            LocationManager.shared.startUpdatingLocation()
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
        if allRouteCoordinates.count > 1 {
            routeOverlay = MKPolyline(coordinates: allRouteCoordinates, count: allRouteCoordinates.count)
            mapView.addOverlay(routeOverlay!)
        }
    }

    // MARK: - Permissions

    private func requestPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToShare: Set<HKSampleType> = [
            HKWorkoutType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKSeriesType.workoutRoute()
        ]

        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]
    }

private func fetchUserWeight() {
        // This is now handled by HealthKitManager
    }
}
