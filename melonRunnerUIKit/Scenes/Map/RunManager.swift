//
//  RunManager.swift
//  melonRunnerUIKit
//
//  Created by Emelyanov Artem on 17.08.2025.
//

import CoreLocation

class RunManager {
    static let shared = RunManager()

        var isRunning: Bool = false
        var isPaused: Bool = false
        var startTime: Date?
        var accumulatedTime: TimeInterval = 0.0
        var locations: [CLLocation] = []
        var totalDistance: Double = 0.0
        var calories: Double = 0.0

        private init() {}
}
