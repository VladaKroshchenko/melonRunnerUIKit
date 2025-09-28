//
//  RunHistoryCell.swift
//  melonRunnerUIKit
//
//  Created by Emelyanov Artem on 27.09.2025.
//

import UIKit
import MapKit

class RunHistoryCell: UITableViewCell {
    
    // MARK: - UI Elements
    private let mapView: MKMapView = {
        let mapView = MKMapView()
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.layer.cornerRadius = 12
        mapView.isUserInteractionEnabled = false
        mapView.showsUserLocation = false
        return mapView
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.MenuButton.text
        return label
    }()
    
    private let distanceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .bold)
        label.textColor = UIColor.MenuButton.text
        return label
    }()
    
    private let caloriesLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.MenuButton.text
        label.layer.opacity = 0.7
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return label
    }()
    
    private let paceLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor.MenuButton.text
        label.layer.opacity = 0.7
        label.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        return label
    }()
    
    private let infoStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 12
        stackView.distribution = .fill
        stackView.alignment = .leading
        return stackView
    }()

    private let bottomStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .fill
        stackView.alignment = .center
        return stackView
    }()

    // MARK: - Initialization
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupLayout()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        selectionStyle = .none
        backgroundColor = UIColor.table
        mapView.delegate = self
        
        contentView.addSubview(mapView)
        contentView.addSubview(infoStackView)

        bottomStackView.addArrangedSubview(caloriesLabel)
        bottomStackView.addArrangedSubview(paceLabel)

        infoStackView.addArrangedSubview(dateLabel)
        infoStackView.addArrangedSubview(distanceLabel)
        infoStackView.addArrangedSubview(bottomStackView)
    }
    
    private func setupLayout() {
        NSLayoutConstraint.activate([
            mapView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            mapView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            mapView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20),
            mapView.widthAnchor.constraint(equalToConstant: 80),
            
            infoStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            infoStackView.leadingAnchor.constraint(equalTo: mapView.trailingAnchor, constant: 16),
            infoStackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            infoStackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -20)
        ])
    }
    
    // MARK: - Configuration
    func configure(with run: Run) {
        dateLabel.text = run.formattedDate
        distanceLabel.text = run.formattedDistance
        caloriesLabel.text = run.formattedCalories
        paceLabel.text = run.formattedPace
        
        setupMapRoute(run.coordinates)
    }
    
    private func setupMapRoute(_ coordinates: [CLLocationCoordinate2D]) {
        mapView.removeOverlays(mapView.overlays)
        
        guard coordinates.count > 1 else {
            mapView.isHidden = true
            return
        }
        
        mapView.isHidden = false
        
        // Set map region to fit the route
        let region = region(for: coordinates)
        mapView.setRegion(region, animated: false)
        
        // Add route overlay
        let polyline = MKPolyline(coordinates: coordinates, count: coordinates.count)
        mapView.addOverlay(polyline)
    }
    
    private func region(for coordinates: [CLLocationCoordinate2D]) -> MKCoordinateRegion {
        var minLat: CLLocationDegrees = 90.0
        var maxLat: CLLocationDegrees = -90.0
        var minLon: CLLocationDegrees = 180.0
        var maxLon: CLLocationDegrees = -180.0
        
        for coordinate in coordinates {
            minLat = min(minLat, coordinate.latitude)
            maxLat = max(maxLat, coordinate.latitude)
            minLon = min(minLon, coordinate.longitude)
            maxLon = max(maxLon, coordinate.longitude)
        }
        
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        
        let span = MKCoordinateSpan(
            latitudeDelta: (maxLat - minLat) * 1.2,
            longitudeDelta: (maxLon - minLon) * 1.2
        )
        
        return MKCoordinateRegion(center: center, span: span)
    }
}

// MARK: - MKMapViewDelegate
extension RunHistoryCell: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let polyline = overlay as? MKPolyline {
            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = UIColor.MenuButton.button
            renderer.lineWidth = 4
            return renderer
        }
        return MKOverlayRenderer()
    }
}
