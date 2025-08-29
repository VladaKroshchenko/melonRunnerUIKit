//
//  WeatherViewModel.swift
//  melonRunnerUIKit
//
//  Created by Emelyanov Artem on 26.08.2025.
//

import SwiftUI
import Combine
import CoreLocation

class WeatherViewModel: ObservableObject {
    @Published var temperature: String = "--"
    @Published var description: String = "--"
    @Published var icon: String = "cloud.sun.fill"

    private var cancellables = Set<AnyCancellable>()

    func fetchWeather(for location: CLLocation) {
        NetworkManager.shared.loadData(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let weatherResponse):
                    self?.temperature = "\(Int(weatherResponse.main.temp))°C"
                    self?.description = weatherResponse.weather.first?.description.capitalized ?? "--"
                    self?.icon = self?.iconName(for: weatherResponse.weather.first?.icon ?? "") ?? "cloud.sun.fill"
                case .failure(let error):
                    print("Не удалось получить данные о погоде: \(error.localizedDescription)")
                }
            }
        }
    }

    private func iconName(for iconCode: String) -> String {
        switch iconCode {
        case "01d": return "sun.max.fill"
        case "01n": return "moon.stars.fill"
        case "02d": return "cloud.sun.fill"
        case "02n": return "cloud.moon.fill"
        case "03d", "03n": return "cloud.fill"
        case "04d", "04n": return "smoke.fill"
        case "09d", "09n": return "cloud.drizzle.fill"
        case "10d": return "cloud.sun.rain.fill"
        case "10n": return "cloud.moon.rain.fill"
        case "11d", "11n": return "cloud.bolt.rain.fill"
        case "13d", "13n": return "cloud.snow.fill"
        case "50d", "50n": return "cloud.fog.fill"
        default: return "sun.max.fill"
        }
    }
}
