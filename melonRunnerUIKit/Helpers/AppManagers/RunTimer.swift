//
//  RunTimer.swift
//  melonRunnerUIKit
//
//  Created by Emelyanov Artem on 20.08.2025.
//

import Foundation

class RunTimer {
    static let shared = RunTimer()

    let runManager = RunManager.shared

    private var timer: Timer?
    private var accumulatedTime: TimeInterval = 0.0

    var startTime: Date?
    var totalTime: TimeInterval = 0.0

    private init() {}

    func startTimer() {
        if timer == nil {
            startTime = Date()
            timer = Timer.scheduledTimer(timeInterval: 1.0, target: self, selector: #selector(updateTimer), userInfo: nil, repeats: true)
//            print("startTimer")
        }
    }

    func stopTimer() {
        timer?.invalidate()
        timer = nil
        startTime = nil
        accumulatedTime = 0.0
//        print("stopTimer accumulatedTime: \(accumulatedTime)")
//        print("stopTimer totalTime: \(totalTime)")
    }

    func pauseTimer() {
        if let startTime = startTime {
            accumulatedTime += Date().timeIntervalSince(startTime)
//            print("pauseTimer accumulatedTime: \(accumulatedTime)")
//            print("pauseTimer totalTime: \(totalTime)")
        }
        timer?.invalidate()
        timer = nil
        startTime = nil
//        print("pauseTimer accumulatedTime: \(accumulatedTime)")
//        print("pauseTimer totalTime: \(totalTime)")
    }

    @objc private func updateTimer() {
        if let startTime = startTime {
            totalTime = Date().timeIntervalSince(startTime) + accumulatedTime
//            print("updateTimer totalTime: \(totalTime)")
//            print("updateTimer totalTimeFormatted: \(formatTime(from: totalTime))")
//            print("updateTimer accumulatedTime: \(accumulatedTime)")
        }
    }
}
