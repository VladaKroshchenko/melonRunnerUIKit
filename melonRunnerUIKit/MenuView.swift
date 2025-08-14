//
//  MenuViewController.swift
//  melonRunnerUIKit
//
//  Created by Emelyanov Artem on 29.07.2025.
//

import UIKit

class MenuView: UIViewController {

    let button: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Open running map", for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupButton()
    }

    private func setupButton() {
        view.addSubview(button)

        NSLayoutConstraint.activate([
            button.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            button.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])

        button.addTarget(self, action: #selector(openMap), for: .touchUpInside)
    }

    @objc func openMap() {
        let mapVC = MapViewController()
        navigationController?.pushViewController(mapVC, animated: true)
    }
}
