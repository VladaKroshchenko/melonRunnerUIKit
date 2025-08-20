//
//  MenuView.swift
//  melonRunnerUIKit
//
//  Created by Emelyanov Artem on 29.07.2025.
//

import UIKit

final class MenuView: UIViewController {

    // MARK: - Private properties
    private let button: UIButton = UIButton()
    private let runLabel = UILabel()
    private let timeLabel = UILabel()
    private let distanceLabel = UILabel()
    private let caloriesLabel = UILabel()
    private let emojiLabel = UILabel()
    private let circleView = UIView()

    let runManager = RunManager.shared
    private var updateTimer: Timer?



//    private let scrollView: UIScrollView = UIScrollView()
//    private let contentView: UIView = UIView()

//    private let imageView: UIImageView = UIImageView()

//    private let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Главная"
        navigationItem.titleView?.tintColor = .label
        view.backgroundColor = UIColor.menuBackground

        setupUI()
        setupLayout()
        startUpdatingButtonTitle()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupButtonText()
    }

    // MARK: - Appearance

    private func setupUI() {

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


        view.addSubview(button)
        button.addSubview(runLabel)
        button.addSubview(timeLabel)
        button.addSubview(distanceLabel)
        button.addSubview(caloriesLabel)
        button.addSubview(circleView)
        button.addSubview(emojiLabel)
    }

    private func setupLayout() {
        button.translatesAutoresizingMaskIntoConstraints = false
        runLabel.translatesAutoresizingMaskIntoConstraints = false
        timeLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        caloriesLabel.translatesAutoresizingMaskIntoConstraints = false
        emojiLabel.translatesAutoresizingMaskIntoConstraints = false
        circleView.translatesAutoresizingMaskIntoConstraints = false


        button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 264).isActive = true
        button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24).isActive = true
        button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true
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
        }
    }

    private func setupButtonText() {

        if runManager.isRunning && !runManager.isPaused {
            runLabel.text = "Текущая пробежка"
            emojiLabel.text = "🏃🏻‍➡️"

            DispatchQueue.main.async {
                self.timeLabel.text = formatTime(from: self.runManager.accumulatedTime + self.runManager.totalTime)
                self.distanceLabel.text = String(format: "%.2f км", self.runManager.totalDistance)
                self.caloriesLabel.text = String(format: "%.0f ккал", self.runManager.calories)
            }
        } else if runManager.isPaused && runManager.isRunning {
            runLabel.text = "Пробежка на паузе"
            DispatchQueue.main.async {
                self.timeLabel.text = formatTime(from: self.runManager.accumulatedTime + self.runManager.totalTime)
            }

        } else if !runManager.isPaused && !runManager.isRunning && runManager.accumulatedTime == 0 {
            runLabel.text = "Пробежка не начата"
            DispatchQueue.main.async {
                self.timeLabel.text = formatTime(from: self.runManager.accumulatedTime + self.runManager.totalTime)
            }

            caloriesLabel.text = "0 ккал"
        } else if !runManager.isPaused && !runManager.isRunning && runManager.accumulatedTime > 0 {
            runLabel.text = "Пробежка окончена"
            DispatchQueue.main.async {
                self.timeLabel.text = formatTime(from: self.runManager.accumulatedTime + self.runManager.totalTime)
            }

            caloriesLabel.text = String(format: "%.0f ккал", runManager.calories)
        }



        //timeLabel.text = "01:09:44"
        //distanceLabel.text = "10,9 km"
        //caloriesLabel.text = "539 kcal"
        //emojiLabel.text = "🏃🏻‍➡️"

    }

    // MARK: - Actions

    @objc func openMap() {
        let mapVC = MapViewController()
        navigationController?.pushViewController(mapVC, animated: true)
    }
}
