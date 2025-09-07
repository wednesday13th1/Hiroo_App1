//
//  MapViewController.swift
//  Hiroo App
//
//  Created by Honoka Nishiyama on 2025/08/27.
//

import UIKit
import MapKit
import CoreLocation

final class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    // UI Elements
    private let mapView = MKMapView()
    private let urlLabel = UILabel()
    private let metroLabel = UILabel()
    private let titleLabel = UILabel()
    private let busLabel = UILabel()
    
    private var locationManager: CLLocationManager!
    private var currentConfig: MapConfig?
    
    // 学校ごとの表示設定
    struct MapConfig {
        let title: String
        let subtitle: String
        let coordinate: CLLocationCoordinate2D
        let url: URL
        let metroText: String
        let busText: String
    }
    
    // 学校→Config マッピング
    private func config(for school: School) -> MapConfig {
        switch school {
        case .hiroo:
            return MapConfig(
                title: "広尾学園",
                subtitle: "Hiroo Gakuen",
                coordinate: CLLocationCoordinate2D(latitude: 35.6514, longitude: 139.7209),
                url: URL(string: "https://www.jorudan.co.jp/")!,
                metroText: "東京メトロ 日比谷線 広尾駅から4番出口すぐ",
                busText: "都バス 黒77 目黒駅前-千駄ヶ谷駅前日赤医療センター下・広尾学園前下車すぐ"
            )
        case .koishikawa:
            return MapConfig(
                title: "広尾学園小石川",
                subtitle: "Hiroo Gakuen Koishikawa",
                coordinate: CLLocationCoordinate2D(latitude: 35.7289, longitude: 139.7468),
                url: URL(string: "https://www.jorudan.co.jp/")!,
                metroText: "都営三田線 千石駅からA4出口徒歩5分",
                busText: "都バス 上58 文京グリーンコート前 バス停より徒歩2分"
            )
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 239/255, green: 252/255, blue: 239/255, alpha: 1)
        
        // Label setup
        [titleLabel, metroLabel, busLabel, urlLabel].forEach { l in
            l.translatesAutoresizingMaskIntoConstraints = false
            l.numberOfLines = 0
        }

        titleLabel.font = UIFont.systemFont(ofSize: 28, weight: .bold)   // Bigger, bold title
        metroLabel.font = UIFont.systemFont(ofSize: 20, weight: .regular) // Bigger body text
        busLabel.font   = UIFont.systemFont(ofSize: 20, weight: .regular)
        urlLabel.font   = UIFont.systemFont(ofSize: 18, weight: .medium)  // Slightly smaller than metro/bus

        
        // Map setup
        mapView.translatesAutoresizingMaskIntoConstraints = false
        mapView.delegate = self
        
        // Location manager
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        // Interactions
        setupURLLabelTap()
        makeLabelSelectable(urlLabel)
        
        // Add subviews
        view.addSubview(titleLabel)
        view.addSubview(metroLabel)
        view.addSubview(busLabel)
        view.addSubview(urlLabel)
        view.addSubview(mapView)
        
        setupConstraints()
        applyConfig(for: UserDefaults.standard.selectedSchool ?? .hiroo)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyConfig(for: UserDefaults.standard.selectedSchool ?? .hiroo)
    }
    
    // MARK: - Constraints
    private func setupConstraints() {
        let g = view.safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: g.topAnchor, constant: 2), // moved even closer to top
            titleLabel.leadingAnchor.constraint(equalTo: g.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: g.trailingAnchor, constant: -16),
            
            metroLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2),
            metroLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metroLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            busLabel.topAnchor.constraint(equalTo: metroLabel.bottomAnchor, constant: 2),
            busLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            busLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            urlLabel.topAnchor.constraint(equalTo: busLabel.bottomAnchor, constant: 2),
            urlLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            urlLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            
            mapView.topAnchor.constraint(equalTo: urlLabel.bottomAnchor, constant: 8),
            mapView.leadingAnchor.constraint(equalTo: g.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: g.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: g.bottomAnchor, constant: -8),
            mapView.heightAnchor.constraint(greaterThanOrEqualToConstant: 220) // shorter so everything shifts up
        ])
    }
    
    // MARK: - Config Apply
    private func applyConfig(for school: School) {
        let cfg = config(for: school)
        currentConfig = cfg
        titleLabel.text = cfg.title
        metroLabel.text = cfg.metroText
        busLabel.text   = cfg.busText
        
        // URL Label with underlined text
        let baseText = "これは設定アプリへのリンクを含む文章です。\n\n乗車案内はこちらのリンクです"
        let attributed = NSMutableAttributedString(string: baseText)
        if let range = baseText.range(of: "乗車案内") {
            let nsRange = NSRange(range, in: baseText)
            attributed.addAttribute(.underlineStyle,
                                    value: NSUnderlineStyle.single.rawValue,
                                    range: nsRange)
            attributed.addAttribute(.foregroundColor,
                                    value: UIColor.systemGreen,
                                    range: nsRange)
        }
        urlLabel.attributedText = attributed
        
        // Map location and pin
        let span   = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
        let region = MKCoordinateRegion(center: cfg.coordinate, span: span)
        mapView.setRegion(region, animated: true)
        
        mapView.removeAnnotations(mapView.annotations)
        let pin = MKPointAnnotation()
        pin.title = cfg.title
        pin.subtitle = cfg.subtitle
        pin.coordinate = cfg.coordinate
        mapView.addAnnotation(pin)
    }
    
    // MARK: - URL Tap
    private func setupURLLabelTap() {
        urlLabel.isUserInteractionEnabled = true
        let tap = UITapGestureRecognizer(target: self, action: #selector(onURLTap))
        urlLabel.addGestureRecognizer(tap)
    }
    
    @objc private func onURLTap() {
        guard let cfg = currentConfig else { return }
        UIApplication.shared.open(cfg.url)
    }
    
    private func makeLabelSelectable(_ label: UILabel) {
        label.numberOfLines = 0
        // UILabel は link 属性を張っても自動でリンクにならないため、タップジェスチャで対応
    }
    
    // MARK: - CLLocationManagerDelegate
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            mapView.showsUserLocation = true
        default:
            mapView.showsUserLocation = false
        }
    }
}

