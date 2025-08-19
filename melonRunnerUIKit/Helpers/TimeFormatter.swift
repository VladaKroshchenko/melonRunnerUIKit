//
//  TimeFormatter.swift
//  melonRunnerUIKit
//
//  Created by Emelyanov Artem on 20.08.2025.
//

import Foundation

func formatTime(from seconds: Double) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.zeroFormattingBehavior = .pad
    return formatter.string(from: seconds) ?? "00:00:00"
}
