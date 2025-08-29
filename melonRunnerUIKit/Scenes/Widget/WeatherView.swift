//
//  WeatherView.swift
//  melonRunnerUIKit
//
//  Created by Emelyanov Artem on 23.08.2025.
//

// b3992e92e6360136830ad185c358b40c


import SwiftUI
import CoreLocation

struct WeatherView: View {
    @StateObject private var viewModel = WeatherViewModel()

    var body: some View {
        HStack {
            Text("Погода")
                .font(.headline)
                .padding(.top, 2)
            Image(systemName: viewModel.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
            Text(viewModel.temperature)
                .font(.title)
            Text(viewModel.description)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.MenuButton.circle.opacity(0.3))
        .border(Color("MenuBackgroundColor"), width: 5)
        .cornerRadius(16)
        .shadow(radius: 5)
        .onAppear {
            NotificationCenter.default.addObserver(forName: .locationDidUpdate, object: nil, queue: .main) { notification in
                if let location = notification.userInfo?["location"] as? CLLocation {
                    viewModel.fetchWeather(for: location)
                }
            }
        }
        .onDisappear {
            NotificationCenter.default.removeObserver(self, name: .locationDidUpdate, object: nil)
        }
    }
}
