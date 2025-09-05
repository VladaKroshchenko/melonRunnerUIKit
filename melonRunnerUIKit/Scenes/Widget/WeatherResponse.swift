//
//  WeatherResponse.swift
//  melonRunnerUIKit
//
//  Created by Emelyanov Artem on 26.08.2025.
//

import Foundation

struct WeatherResponse: Codable {
    struct Main: Codable {
        let temp: Double
        let feels_like: Double
        let humidity: Int
        let pressure: Int
    }

    struct Weather: Codable {
        let description: String
        let icon: String
    }

    struct Sys: Codable {
        let sunrise: Int
        let sunset: Int
    }

    let weather: [Weather]
    let main: Main
    let sys: Sys
    let name: String

    var sunsetDate: Date {
        Date(timeIntervalSince1970: TimeInterval(sys.sunset))
    }

    var sunriseDate: Date {
        Date(timeIntervalSince1970: TimeInterval(sys.sunrise))
    }
}

struct GeocodingResponse: Codable {
    let name: String
    let local_names: [String: String]?
    let lat: Double
    let lon: Double
    let country: String

    var russianName: String {
        return local_names?["ru"] ?? name
    }
}
