//
//  HomeViewController.swift
//  Koshatnik
//
//  Created by Konstantin Kulakov on 11.08.2025.
//

// TODO: - Удалить этот файл

import UIKit

final class HomeViewController: UIViewController {
    
    // MARK: - Private properties
    private let scrollView: UIScrollView = UIScrollView()
    private let contentView: UIView = UIView()

    private let imageView: UIImageView = UIImageView()
    private let actionButton: UIButton = UIButton()
    private let textField: UITextField = UITextField()

    private let activityIndicator: UIActivityIndicatorView = UIActivityIndicatorView(style: .large)

    // MARK: - Life cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Главная"

        view.backgroundColor = .systemBackground

        //setupKeyboard()
        setupUI()
        setupLayout()
        didTapActionButton()

    }
    
    
    // MARK: - Setup UI
    private func setupUI() {
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .lightGray
        imageView.clipsToBounds = true
        
        actionButton.setTitle("Генерировать кота!", for: .normal)
        actionButton.titleLabel?.font = .boldSystemFont(ofSize: 19)
        actionButton.backgroundColor = UIColor(named: "buttonPrimary")
        actionButton.layer.cornerRadius = 14

        actionButton.addTarget(self, action: #selector(didTapActionButton), for: .touchUpInside)
        
        scrollView.contentInset.bottom = 44
        scrollView.verticalScrollIndicatorInsets.bottom = 44
        
        scrollView.alwaysBounceVertical = true
        
        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        textField.placeholder = "Текст мема"
        textField.backgroundColor = .secondarySystemBackground
        textField.layer.cornerRadius = 14

        textField.setContentHuggingPriority(.required, for: .vertical)
        textField.setContentCompressionResistancePriority(.required, for: .vertical)

        activityIndicator.hidesWhenStopped = true
        activityIndicator.color = .systemGray

        //contentView.addSubviews(imageView, actionButton, textField, activityIndicator)
    }
    
    // MARK: - Layout
    
    private func setupLayout() {
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        contentView.translatesAutoresizingMaskIntoConstraints = false
        imageView.translatesAutoresizingMaskIntoConstraints = false
        actionButton.translatesAutoresizingMaskIntoConstraints = false
        textField.translatesAutoresizingMaskIntoConstraints = false
        activityIndicator.translatesAutoresizingMaskIntoConstraints = false

        scrollView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor).isActive = true
        contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor).isActive = true
        contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor).isActive = true
        contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor).isActive = true
        
        contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor).isActive = true
        
        imageView.topAnchor.constraint(equalTo: contentView.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor).isActive = true
        imageView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: imageView.widthAnchor, multiplier: 1).isActive = true
        
        actionButton.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 12).isActive = true
        actionButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
        actionButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
        actionButton.heightAnchor.constraint(equalToConstant: 44).isActive = true

        activityIndicator.centerXAnchor.constraint(equalTo: actionButton.centerXAnchor).isActive = true
        activityIndicator.centerYAnchor.constraint(equalTo: actionButton.centerYAnchor).isActive = true

        textField.topAnchor.constraint(equalTo: actionButton.bottomAnchor, constant: 12).isActive = true
        textField.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16).isActive = true
        textField.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16).isActive = true
        textField.bottomAnchor.constraint(equalTo: contentView.bottomAnchor).isActive = true
        textField.heightAnchor.constraint(equalToConstant: 44).isActive = true
    }
}

private extension HomeViewController {
    
    @objc
    private func didTapActionButton() {
        actionButton.setTitle(" ", for: .normal)
        activityIndicator.startAnimating()

        let text = textField.text?.isEmpty == false ? textField.text! : "Not hehe"
        loadImage(with: text)
    }
    
    func loadImage(with text: String) {
        guard let url = URL(string: "https://cataas.com/cat/cute/says/\(text)") else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, _, _ in
            guard
                let data = data,
                let image = UIImage(data: data)
            else {
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                self?.imageView.image = image

                self?.activityIndicator.stopAnimating()
                self?.actionButton.setTitle("Генерировать кота!", for: .normal)

                self?.view.setNeedsLayout()
                self?.view.layoutIfNeeded()
            }
        }
        task.resume()
    }
}
