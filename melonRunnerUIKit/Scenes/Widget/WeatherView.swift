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
        HStack(spacing: 64) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.cityName)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.8)
                    .fixedSize(horizontal: false, vertical: true)
                    .foregroundStyle(Color("MenuButton/TextColor"))
                Text(viewModel.temperature)
                    .font(.system(size: 32, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color("MenuButton/TextColor"))
                Text(viewModel.tempFeelsLike)
                    .font(.caption)
                    .foregroundStyle(Color("MenuButton/TextColor"))
                    //.foregroundColor(.secondary)
            }.layoutPriority(0)

            //Spacer()

            VStack(spacing: 8) {
                Image(systemName: viewModel.icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 56, height: 56)
                    .foregroundColor(viewModel.iconColor)
                    .symbolRenderingMode(.hierarchical)
                    .fixedSize()
                Text(viewModel.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .frame(minWidth: 80)
                    .foregroundStyle(Color("MenuButton/TextColor"))
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.MenuButton.circle.opacity(0.3))
        )
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)

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
