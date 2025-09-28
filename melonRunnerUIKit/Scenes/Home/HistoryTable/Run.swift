//
//  Run.swift
//  melonRunnerUIKit
//
//  Created by Emelyanov Artem on 27.09.2025.
//

import Foundation
import CoreLocation

struct Run {
    let id: String
    let date: Date
    let distance: Double // in kilometers
    let calories: Double // in kcal
    let duration: TimeInterval // in seconds
    let pace: Double // in min/km
    let coordinates: [CLLocationCoordinate2D]
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ru_RU")
        return formatter.string(from: date)
    }
    
    var formattedDistance: String {
        return String(format: "%.2f км", distance)
    }
    
    var formattedCalories: String {
        return String(format: "%.0f ккал", calories)
    }
    
    var formattedDuration: String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    var formattedPace: String {
        guard pace.isFinite && pace >= 0 else {
                return "00:00 /км"
            }
        
        let minutes = Int(pace)
        let seconds = Int((pace - Double(minutes)) * 60)
        return String(format: "%02d:%02d /км", minutes, seconds)
    }
}
