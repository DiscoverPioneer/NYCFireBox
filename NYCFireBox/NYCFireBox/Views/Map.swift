import Foundation
import MapKit
import CoreLocation

private enum MapType: Int {
    case standard
    case hybrid
    case satellite
}

class Map: UIView {
    @IBOutlet var contentView: UIView!
    @IBOutlet weak var mapView: PioneerMapView!
    @IBOutlet weak var mapTypeSegmentedControl: UISegmentedControl!
    @IBOutlet weak var userLocationButton: UIButton!

    private var markerColors: [String: UIColor] = [:]

    override init(frame: CGRect) {
        super.init(frame: frame)
        loadNib()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        loadNib()
    }

    private func loadNib() {
        Bundle.main.loadNibNamed("Map", owner: self , options: nil)
        addSubview(contentView)
        contentView.frame = self.bounds
        contentView.autoresizingMask = [.flexibleHeight, .flexibleWidth]
        setupViews()
    }

    private func setupViews() {
        mapView.delegate = self
        mapView.showsUserLocation = true
        if #available(iOS 13.0, *) {
            contentView.backgroundColor = .systemBackground
            mapTypeSegmentedControl.selectedSegmentTintColor = .systemRed
            userLocationButton.tintColor = .systemRed
        } else {
            contentView.backgroundColor = .white
            userLocationButton.tintColor = .red
        }
        mapTypeSegmentedControl.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16),
                                                        NSAttributedString.Key.foregroundColor: UIColor.lightGray],
                                                       for: .normal)
        mapTypeSegmentedControl.setTitleTextAttributes([NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 18),
                                                        NSAttributedString.Key.foregroundColor: UIColor.gray],
                                                       for: .selected)
        mapTypeSegmentedControl.selectedSegmentIndex = MapType.standard.rawValue

    }

    func addBorder(color: UIColor) {
        layer.borderColor = color.cgColor
        layer.borderWidth = 1
        layer.cornerRadius = 8
        layer.masksToBounds = true
    }

    func setupMapRegion(startCoordinates: CLLocationCoordinate2D, radius: Double) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(startCoordinates,
                                                                  radius * 1.5,
                                                                  radius * 1.5)
        mapView.setRegion(coordinateRegion, animated: true)
        mapView.showsUserLocation = true
    }

    func addMarker(toLocation location: Location, color: UIColor) {
        location.toCoordinates { [weak self] (coordinates) in
            guard let coordinates = coordinates  else { return }
            let pin = MKPointAnnotation()
            pin.title = String(describing: location.name)
            pin.coordinate = coordinates
            self?.mapView.addAnnotation(pin)
            self?.markerColors[location.name] = color
        }
    }

    //MARK: - Actions 
    @IBAction func onMapTypeChanged(_ sender: UISegmentedControl) {
        let selectedMapType = MapType(rawValue: sender.selectedSegmentIndex) ?? .standard
        switch selectedMapType {
        case .satellite: mapView.mapType = .satelliteFlyover
        case .hybrid: mapView.mapType = .hybridFlyover
        case .standard: mapView.mapType = .standard
        }
    }

    @IBAction func onUserLocation(_ sender: UIButton) {
        if CLLocationManager.authorizationStatus() == .authorizedWhenInUse {
            setupMapRegion(startCoordinates: mapView.userLocation.coordinate,
                           radius: 1000)
        }
    }
}

extension Map: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "annotationReuseID")
        annotationView.isEnabled = true
        annotationView.canShowCallout = true
        annotationView.leftCalloutAccessoryView = UILabel()

        if annotation.isKind(of: MKUserLocation.self) {
            annotationView.markerTintColor = .green
            return annotationView
        }

        if let annotationName = annotation.title ?? "" {
            annotationView.markerTintColor = markerColors[annotationName] ?? .red
        }
        
        if annotation.title == "*" {
            annotationView.markerTintColor = .yellow
            annotationView.displayPriority = .required
        }

        if annotationView.markerTintColor == .blue {
            annotationView.displayPriority = .required
        }
        return annotationView
    }
}
