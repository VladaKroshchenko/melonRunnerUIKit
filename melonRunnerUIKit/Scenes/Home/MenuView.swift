//
//  MenuView.swift
//  melonRunnerUIKit
//
//  Created by Emelyanov Artem on 29.07.2025.
//

import UIKit
import SwiftUI
import MapKit
import HealthKit
import Foundation

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

    // MARK: - Run History Table
    private let historyTitleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "История пробежек"
        label.font = UIFont.systemFont(ofSize: 18, weight: .bold)
        label.textColor = UIColor.historyTitle
        return label
    }()
    
    private let historyTableView: UITableView = {
        let tableView = UITableView()
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = UIColor.table
        tableView.separatorStyle = .singleLine
        tableView.separatorInset = UIEdgeInsets(top: 0, left: 60, bottom: 0, right: 60)
        tableView.register(RunHistoryCell.self, forCellReuseIdentifier: "RunHistoryCell")
        return tableView
    }()

    private let placeholderView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.backgroundColor = .clear
        return view
    }()

    private let placeholderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        // Установить нужную картинку
        imageView.image = UIImage(named: "PlaceHolderImage")
        return imageView
    }()

    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.text = "Нет истории или не выдан доступ к здоровью"
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = UIFont.systemFont(ofSize: 16)
        return label
    }()

    //private var runs: [melonRunnerUIKit.Run] = []
    private var runs: [Run] = []
    
    let runManager = RunManager.shared
    let runTimer = RunTimer.shared
    private var updateTimer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.menuBackground
        
        setupUI()
        setupLayout()
        startUpdatingButtonTitle()
        loadRunHistory()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(healthKitPermissionsChanged),
            name: NSNotification.Name("HealthKitPermissionsChanged"),
            object: nil
        )
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupButtonText()
        loadRunHistory()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    // MARK: - Appearance
    
    private func setupUI() {
        
        // Настройка вью кнопки
        contentView.backgroundColor = UIColor.menuBackground
        rectangleView.backgroundColor = UIColor.MenuButton.button
        rectangleView.layer.cornerRadius = 16
        
        // Настройка кнопки
        button.backgroundColor = UIColor.MenuButton.button
        button.layer.cornerRadius = 30
        
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

        // Настройка таблицы истории пробежек
        historyTableView.delegate = self
        historyTableView.dataSource = self
        historyTableView.isScrollEnabled = false
        historyTableView.layer.cornerRadius = 16

        view.addSubview(contentView)
        contentView.addSubview(button)
        contentView.addSubview(rectangleView)
        button.addSubview(runLabel)
        button.addSubview(timeLabel)
        button.addSubview(distanceLabel)
        button.addSubview(caloriesLabel)
        button.addSubview(circleView)
        button.addSubview(emojiLabel)
        view.addSubview(historyTitleLabel)
        view.addSubview(historyTableView)

        contentView.addSubview(placeholderView)
        placeholderView.addSubview(placeholderImageView)
        placeholderView.addSubview(placeholderLabel)

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
        
        // Layout для таблицы истории пробежек
        historyTitleLabel.topAnchor.constraint(equalTo: view.centerYAnchor, constant: -36).isActive = true
        historyTitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24).isActive = true
        historyTitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true

        historyTableView.topAnchor.constraint(equalTo: historyTitleLabel.bottomAnchor, constant: 8).isActive = true
        historyTableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24).isActive = true
        historyTableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true
        historyTableView.heightAnchor.constraint(equalToConstant: 360).isActive = true

        // Constraints для placeholderView
        placeholderView.topAnchor.constraint(equalTo: historyTitleLabel.bottomAnchor, constant: 8).isActive = true
        placeholderView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24).isActive = true
        placeholderView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24).isActive = true
        placeholderView.heightAnchor.constraint(equalToConstant: 360).isActive = true

        // Constraints для элементов внутри placeholderView
        placeholderImageView.centerXAnchor.constraint(equalTo: placeholderView.centerXAnchor).isActive = true
        placeholderImageView.centerYAnchor.constraint(equalTo: placeholderView.centerYAnchor, constant: -20).isActive = true
        placeholderImageView.widthAnchor.constraint(equalToConstant: 120).isActive = true
        placeholderImageView.heightAnchor.constraint(equalToConstant: 120).isActive = true

        placeholderLabel.topAnchor.constraint(equalTo: placeholderImageView.bottomAnchor, constant: 16).isActive = true
        placeholderLabel.leadingAnchor.constraint(equalTo: placeholderView.leadingAnchor, constant: 16).isActive = true
        placeholderLabel.trailingAnchor.constraint(equalTo: placeholderView.trailingAnchor, constant: -16).isActive = true

        // Layout для SwiftUI View
        if let weatherView = weatherHostingController?.view {
            NSLayoutConstraint.activate([
                //TODO: кривое скорее всего
                weatherView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 120),
                //weatherView.topAnchor.constraint(equalTo: historyTableView.bottomAnchor, constant: 20),
                weatherView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 24),
                weatherView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -24),
                weatherView.bottomAnchor.constraint(equalTo: rectangleView.bottomAnchor, constant: 36)
                //weatherView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
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
    
    // MARK: - Run History
    private func loadRunHistory() {
        HealthKitManager.shared.fetchLastRuns { [weak self] runs in
            guard let self = self else { return }
            
            if let runs = runs {
                self.runs = runs
            } else {
                self.runs = []
            }
            
            DispatchQueue.main.async {
                self.historyTableView.reloadData()
                self.updateHistoryVisibility()
            }
        }
    }

    private func updateHistoryVisibility() {
        let isEmpty = runs.isEmpty
        historyTitleLabel.isHidden = isEmpty
        historyTableView.isHidden = isEmpty
        placeholderView.isHidden = !isEmpty
    }

    @objc private func healthKitPermissionsChanged() {
        // Перезагрузить историю после получения пермишенов
        loadRunHistory()
    }

    // MARK: - Actions
    
    @objc func openMap() {
        let mapVC = MapViewController()
        navigationController?.pushViewController(mapVC, animated: true)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

// MARK: - UITableViewDataSource
extension MenuView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return runs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "RunHistoryCell", for: indexPath) as! RunHistoryCell
        let run = runs[indexPath.row]
        cell.configure(with: run)
        return cell
    }
}

// MARK: - UITableViewDelegate
extension MenuView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 120
    }
}
