//
//  NetworkManager.swift
//  melonRunnerUIKit
//
//  Created by Emelyanov Artem on 26.08.2025.
//

import Foundation

enum NetworkError: Error {
    case invalidURL
    case emptyData
}

final class NetworkManager {
    static let appId = "b3992e92e6360136830ad185c358b40c"

    static let shared = NetworkManager()

    private init() {}

    func loadData(latitude: Double, longitude: Double, completion: @escaping (Result<WeatherResponse, Error>) -> Void) {
        guard let url = URL(string: "https://api.openweathermap.org/data/2.5/weather?lat=\(latitude)&lon=\(longitude)&appid=\(Self.appId)&units=metric&lang=ru") else {
            completion(.failure(NetworkError.invalidURL))
            return
        }

        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let data else {
                completion(.failure(NetworkError.emptyData))
                return
            }

            let decoder = JSONDecoder()
            do {
                let weather = try decoder.decode(WeatherResponse.self, from: data)
                completion(.success(weather))
            } catch {
                completion(.failure(error))
            }
        }

        dataTask.resume()
    }
}
