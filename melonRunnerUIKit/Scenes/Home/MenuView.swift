//
//  MenuView.swift
//  melonRunnerUIKit
//
//  Created by Emelyanov Artem on 29.07.2025.
//

import UIKit
import SwiftUI

final class MenuView: UIViewController {

    // MARK: - Private properties
    private let contentView: UIView = UIView()
    private let rectangleView: UIView = UIView()
    private var weatherHostingController: UIHostingController<WeatherView>!

    private let button: UIButton = UIButton()
    private let runLabel = UILabel()
    private let timeLabel = UILabel()
    private let distanceLabel = UILabel()
    private let caloriesLabel = UILabel()
    private let emojiLabel = UILabel()
    private let circleView = UIView()

    let runManager = RunManager.shared
    let runTimer = RunTimer.shared
    private var updateTimer: Timer?



//    private let scrollView: UIScrollView = UIScrollView()
//    private let contentView: UIView = UIView()

//    private let imageView: UIImageView = UIImageView()

//    private let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        //navigationItem.title = "Главная"
        //navigationItem.titleView?.tintColor = .label
        view.backgroundColor = UIColor.menuBackground

        setupUI()
        setupLayout()
        startUpdatingButtonTitle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupButtonText()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

//        // Очищаем LocationManager
//        if let weatherView = weatherHostingController?.rootView {
//            weatherView.resetLocationManager()
//        }
    }


    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if let weatherView = weatherHostingController?.view {
            if let borderColor = UIColor(named: "MenuBackgroundColor") {
                weatherView.layer.borderColor = borderColor.cgColor
            }
        }
    }

    // MARK: - Appearance

    private func setupUI() {

        // Настройка вью кнопки
        contentView.backgroundColor = UIColor.menuBackground
        rectangleView.backgroundColor = UIColor.MenuButton.button
        rectangleView.layer.cornerRadius = 16

        // Настройка кнопки
        //button.setTitle("Open running map", for: .normal)
        button.backgroundColor = UIColor.MenuButton.button
        button.layer.cornerRadius = 30
        //button.layer.shadowColor = UIColor.black.cgColor
        //button.layer.shadowOffset = CGSize(width: 0, height: 4)
        //button.layer.shadowOpacity = 0.25
        //button.layer.shadowRadius = 3

        button.addTarget(self, action: #selector(openMap), for: .touchUpInside)

        // Настройка лейблов
        runLabel.font = UIFont.boldSystemFont(ofSize: 14)
        runLabel.textColor = UIColor.MenuButton.text
        timeLabel.font = UIFont.systemFont(ofSize: 12)
        timeLabel.textColor = UIColor.MenuButton.text
        timeLabel.layer.opacity = 0.9
        distanceLabel.font = UIFont.boldSystemFont(ofSize: 14)
        distanceLabel.textColor = UIColor.MenuButton.text
        caloriesLabel.font = UIFont.systemFont(ofSize: 12)
        caloriesLabel.textColor = UIColor.MenuButton.text
        caloriesLabel.layer.opacity = 0.9

        // Настройка эмодзи
        emojiLabel.font = UIFont.systemFont(ofSize: 40)
        emojiLabel.textAlignment = .center
        //emojiLabel.contentMode = .scaleAspectFit

        // Настройка кружка в кнопке
        circleView.backgroundColor = UIColor.MenuButton.circle
        circleView.layer.cornerRadius = 20
        circleView.clipsToBounds = true

        view.addSubview(contentView)
        contentView.addSubview(button)
        contentView.addSubview(rectangleView)
        button.addSubview(runLabel)
        button.addSubview(timeLabel)
        button.addSubview(distanceLabel)
        button.addSubview(caloriesLabel)
        button.addSubview(circleView)
        button.addSubview(emojiLabel)

        // Добавление SwiftUI View
        let weatherView = WeatherView()
        weatherHostingController = UIHostingController(rootView: weatherView)
        if let weatherView = weatherHostingController?.view {
            weatherView.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview(weatherView)
        }

        // Настройки виджета погоды
        if let weatherView = weatherHostingController?.view {
            weatherView.layer.cornerRadius = 16
            weatherView.clipsToBounds = true
            weatherView.backgroundColor = .white
            weatherView.layer.borderWidth = 5
        }


    }

    private func setupLayout() {
        contentView.translatesAutoresizingMaskIntoConstraints = false
        rectangleView.translatesAutoresizingMaskIntoConstraints = false
        button.translatesAutoresizingMaskIntoConstraints = false
        runLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        caloriesLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        circleView.translatesAutoresizingMaskIntoConstraints = false


        contentView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        contentView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.5).isActive = true

        rectangleView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        rectangleView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        rectangleView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        rectangleView.heightAnchor.constraint(equalToConstant: 220).isActive = true

        // Layout для SwiftUI View
        if let weatherView = weatherHostingController?.view {
            NSLayoutConstraint.activate([
                weatherView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 120),
                weatherView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
                weatherView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
                weatherView.bottomAnchor.constraint(equalTo: rectangleView.bottomAnchor, constant: 36)
                //weatherView.heightAnchor.constraint(equalToConstant: 128)
            ])
        }

        button.topAnchor.constraint(equalTo: contentView.safeAreaLayoutGuide.topAnchor, constant: 190).isActive = true
        button.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24).isActive = true
        button.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24).isActive = true
        button.heightAnchor.constraint(equalToConstant: 64).isActive = true

        runLabel.topAnchor.constraint(equalTo: button.topAnchor, constant: 17).isActive = true
        runLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 80).isActive = true

        distanceLabel.topAnchor.constraint(equalTo: button.topAnchor, constant: 17).isActive = true
        distanceLabel.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -25).isActive = true

        timeLabel.topAnchor.constraint(equalTo: button.topAnchor, constant: 34).isActive = true
        timeLabel.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 80).isActive = true

        caloriesLabel.topAnchor.constraint(equalTo: button.topAnchor, constant: 34).isActive = true
        caloriesLabel.trailingAnchor.constraint(equalTo: button.trailingAnchor, constant: -25).isActive = true

        circleView.topAnchor.constraint(equalTo: button.topAnchor, constant: 12).isActive = true
        circleView.leadingAnchor.constraint(equalTo: button.leadingAnchor, constant: 20).isActive = true
        circleView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        circleView.heightAnchor.constraint(equalToConstant: 40).isActive = true

        emojiLabel.topAnchor.constraint(equalTo: circleView.topAnchor).isActive = true
        emojiLabel.leadingAnchor.constraint(equalTo: circleView.leadingAnchor, constant: 4).isActive = true
        emojiLabel.widthAnchor.constraint(equalToConstant: 40).isActive = true
        emojiLabel.heightAnchor.constraint(equalToConstant: 40).isActive = true

    }

    private func startUpdatingButtonTitle() {
        // Создаем таймер, который будет обновлять текст кнопки каждую секунду
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.setupButtonText()
            DispatchQueue.main.async { [self] in
                self?.timeLabel.text = formatTime(from: self?.runTimer.totalTime ?? 0.0)
                self?.distanceLabel.text = String(format: "%.2f км", self?.runManager.totalDistance ?? 0.0)
                self?.caloriesLabel.text = String(format: "%.0f ккал", self?.runManager.calories ?? 0.0)
            }
        }
    }

    private func setupButtonText() {

        if runManager.isRunning && !runManager.isPaused {
            runLabel.text = "Текущая пробежка"
            emojiLabel.text = "🏃🏻‍➡️"
            
        } else if runManager.isPaused && runManager.isRunning {
            runLabel.text = "Пробежка на паузе"
            emojiLabel.text = "🚶🏻‍➡️"

        } else if !runManager.isPaused && !runManager.isRunning && runTimer.totalTime == 0 {
            runLabel.text = "Пробежка не начата"
            emojiLabel.text = "🧍🏻"
            timeLabel.text = "00:00:00"
            distanceLabel.text = "0.00 км"
            caloriesLabel.text = "0 ккал"

        } else if !runManager.isPaused && !runManager.isRunning && runTimer.totalTime > 0 {
            runLabel.text = "Пробежка окончена"
            emojiLabel.text = "🧍🏻"
        }
    }

    // MARK: - Actions

    @objc func openMap() {
        let mapVC = MapViewController()
        navigationController?.pushViewController(mapVC, animated: true)
    }
}
