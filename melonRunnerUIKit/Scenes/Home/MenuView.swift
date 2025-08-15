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

//    private let scrollView: UIScrollView = UIScrollView()
//    private let contentView: UIView = UIView()

//    private let imageView: UIImageView = UIImageView()

//    private let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .large)

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Главная"
        view.backgroundColor = .white

        setupUI()
        setupLayout()
    }

    private func setupUI() {

        button.setTitle("Open running map", for: .normal)
        button.backgroundColor = UIColor(red: 93/255, green: 99/255, blue: 209/255, alpha: 1)
        button.layer.cornerRadius = 32

        button.addTarget(self, action: #selector(openMap), for: .touchUpInside)

        view.addSubview(button)
    }

    private func setupLayout() {
        button.translatesAutoresizingMaskIntoConstraints = false

        button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 264).isActive = true
        button.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24).isActive = true
        button.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true

        //button.widthAnchor.constraint(equalToConstant: 327).isActive = true // Установите желаемую ширину
        button.heightAnchor.constraint(equalToConstant: 64).isActive = true // Установите желаемую высоту

    }

    @objc func openMap() {
        let mapVC = MapViewController()
        navigationController?.pushViewController(mapVC, animated: true)
    }
}
