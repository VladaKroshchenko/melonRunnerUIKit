//
//  HealthKitManager.swift
//  melonRunnerUIKit
//
//  Created by Emelyanov Artem on 27.09.2025.
//

import HealthKit
import CoreLocation

class HealthKitManager {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    private var routeBuilder: HKWorkoutRouteBuilder?
    private var workoutRoutes: [HKWorkoutRoute] = []
    private var userWeight: Double = 70.0 // По умолчанию 70 кг
    
    private init() {}
    
    // MARK: - Permissions
    
    func requestPermissions(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else { 
            completion(false)
            return
        }
        
        let typesToShare: Set<HKSampleType> = [
            HKWorkoutType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKSeriesType.workoutRoute()
        ]
        
        let typesToRead: Set<HKObjectType> = [
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKSeriesType.workoutRoute(),
            HKWorkoutType.workoutType()
        ]
        
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] _, error in
            let workoutType = HKObjectType.workoutType()
            let status = self?.healthStore.authorizationStatus(for: workoutType) ?? .notDetermined

            if status == .sharingAuthorized {
                self?.fetchUserWeight()
                DispatchQueue.main.async {
                    completion(true)
                }
            } else {
                if let error = error {
                    print("Ошибка авторизации HealthKit: \(error.localizedDescription)")
                }
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    private func fetchUserWeight() {
        guard let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass) else { return }
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: bodyMassType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] _, samples, error in
            if let sample = samples?.first as? HKQuantitySample {
                self?.userWeight = sample.quantity.doubleValue(for: .gramUnit(with: .kilo))
            }
        }
        healthStore.execute(query)
    }
    
    // MARK: - Workout Management
    
    func startWorkout() {
        routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
        workoutRoutes.removeAll()
    }
    
    func pauseWorkout() {
        routeBuilder = nil
    }
    
    func resumeWorkout() {
        routeBuilder = HKWorkoutRouteBuilder(healthStore: healthStore, device: nil)
    }
    
    func savePartialRoute(locations: [CLLocation], completion: @escaping (Bool) -> Void) {
        guard let routeBuilder = routeBuilder, !locations.isEmpty else { 
            completion(false)
            return
        }
        
        routeBuilder.insertRouteData(locations) { success, error in
            if !success {
                print("Ошибка сохранения части маршрута: \(error?.localizedDescription ?? "")")
            }
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    func saveWorkout(
        startDate: Date,
        endDate: Date,
        duration: TimeInterval,
        calories: Double,
        distance: Double,
        locations: [CLLocation],
        completion: @escaping (Bool) -> Void
    ) {
        // Создание объекта пробежки
        let workout = HKWorkout(
            activityType: .running,
            start: startDate,
            end: endDate,
            duration: duration,
            totalEnergyBurned: HKQuantity(unit: .kilocalorie(), doubleValue: calories),
            totalDistance: HKQuantity(unit: .meter(), doubleValue: distance * 1000),
            device: nil,
            metadata: nil
        )
        
        // Сохранение пробежки
        healthStore.save(workout) { [weak self] success, error in
            if success {
                // Сохранение маршрута, если он есть
                if let routeBuilder = self?.routeBuilder, !locations.isEmpty {
                    routeBuilder.insertRouteData(locations) { success, error in
                        if !success {
                            print("Ошибка добавления финальных локаций: \(error?.localizedDescription ?? "")")
                        }
                        // Завершаем маршрут с привязкой к workout
                        routeBuilder.finishRoute(with: workout, metadata: nil) { route, error in
                            if let route = route {
                                self?.workoutRoutes.append(route)
                                self?.healthStore.add([route], to: workout) { success, error in
                                    if !success {
                                        print("Ошибка добавления маршрута: \(error?.localizedDescription ?? "")")
                                    }
                                    self?.resetWorkout()
                                    DispatchQueue.main.async {
                                        completion(success)
                                    }
                                }
                            } else {
                                print("Ошибка завершения маршрута: \(error?.localizedDescription ?? "")")
                                self?.resetWorkout()
                                DispatchQueue.main.async {
                                    completion(false)
                                }
                            }
                        }
                    }
                } else {
                    self?.resetWorkout()
                    DispatchQueue.main.async {
                        completion(true)
                    }
                }
            } else {
                print("Ошибка сохранения пробежки: \(error?.localizedDescription ?? "")")
                self?.resetWorkout()
                DispatchQueue.main.async {
                    completion(false)
                }
            }
        }
    }
    
    private func resetWorkout() {
        routeBuilder = nil
        workoutRoutes = []
    }
    
    // MARK: - Data Samples
    
    func saveDistanceSample(
        distance: Double,
        startTime: Date,
        endTime: Date,
        completion: @escaping (Bool) -> Void
    ) {
        guard let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else {
            completion(false)
            return
        }
        
        let distanceQuantity = HKQuantity(unit: .meter(), doubleValue: distance)
        let distanceSample = HKQuantitySample(
            type: distanceType,
            quantity: distanceQuantity,
            start: startTime,
            end: endTime
        )
        
        healthStore.save(distanceSample) { success, error in
            if !success {
                print("Ошибка сохранения дистанции: \(error?.localizedDescription ?? "")")
            }
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    func saveCaloriesSample(
        calories: Double,
        startTime: Date,
        endTime: Date,
        completion: @escaping (Bool) -> Void
    ) {
        guard let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            completion(false)
            return
        }
        
        let energyQuantity = HKQuantity(unit: .kilocalorie(), doubleValue: calories)
        let energySample = HKQuantitySample(
            type: energyType,
            quantity: energyQuantity,
            start: startTime,
            end: endTime
        )
        
        healthStore.save(energySample) { success, error in
            if !success {
                print("Ошибка сохранения калорий: \(error?.localizedDescription ?? "")")
            }
            DispatchQueue.main.async {
                completion(success)
            }
        }
    }
    
    // MARK: - Properties
    
    var currentUserWeight: Double {
        return userWeight
    }
    
    // MARK: - Fetch Workout History
    
    func fetchLastRuns(completion: @escaping ([Run]?) -> Void) {
        let workoutType = HKObjectType.workoutType()
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        let query = HKSampleQuery(
            sampleType: workoutType,
            predicate: HKQuery.predicateForWorkouts(with: .running),
            limit: 30,
            sortDescriptors: [sortDescriptor]
        ) { [weak self] _, samples, error in
            guard let workouts = samples as? [HKWorkout], error == nil else {
                print("Ошибка получения тренировок: \(error?.localizedDescription ?? "Неизвестная ошибка")")
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            self?.processWorkouts(workouts, completion: completion)
        }
        
        healthStore.execute(query)
    }
    
    private func processWorkouts(_ workouts: [HKWorkout], completion: @escaping ([Run]?) -> Void) {
        var runs: [Run] = []
        let group = DispatchGroup()
        
        for workout in workouts {
            group.enter()
            
            // Получаем расстояние
            let distance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
            let distanceInKm = distance / 1000.0
            
            // Получаем калории
            let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
            
            // Получаем продолжительность
            let duration = workout.duration
            
            // Рассчитываем темп (мин/км)
            let pace = distanceInKm > 0 ? duration / 60.0 / distanceInKm : 0 // Переводим в минуты и делим на км

            // Получаем маршрут
            self.fetchRoute(for: workout) { coordinates in
                let run = Run(
                    id: workout.uuid.uuidString,
                    date: workout.startDate,
                    distance: distanceInKm,
                    calories: calories,
                    duration: duration,
                    pace: pace,
                    coordinates: coordinates
                )
                runs.append(run)
                group.leave()
            }
        }
        
        group.notify(queue: .main) {
            // Сортируем по дате (новые первыми)
            runs.sort { $0.date > $1.date }
            completion(runs)
        }
    }
    
    private func fetchRoute(for workout: HKWorkout, completion: @escaping ([CLLocationCoordinate2D]) -> Void) {
        let predicate = HKQuery.predicateForObjects(from: workout)
        
        let routeType = HKSeriesType.workoutRoute()
        
        let query = HKSampleQuery(sampleType: routeType, predicate: predicate, limit: 1, sortDescriptors: nil) { _, samples, error in
            guard let routes = samples as? [HKWorkoutRoute], let route = routes.first, error == nil else {
                DispatchQueue.main.async {
                    completion([])
                }
                return
            }
            
            self.fetchRouteData(for: route, completion: completion)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchRouteData(for route: HKWorkoutRoute, completion: @escaping ([CLLocationCoordinate2D]) -> Void) {
        var coordinates: [CLLocationCoordinate2D] = []
        
        let query = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
            guard let locations = locations, error == nil else {
                if error != nil {
                    print("Ошибка получения данных маршрута: \(error!.localizedDescription)")
                }
                return
            }
            
            for location in locations {
                coordinates.append(location.coordinate)
            }
            
            if done {
                DispatchQueue.main.async {
                    completion(coordinates)
                }
            }
        }
        
        healthStore.execute(query)
    }
}
