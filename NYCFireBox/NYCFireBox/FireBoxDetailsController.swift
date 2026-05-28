import Foundation
import UIKit
import MapKit

class FireBoxDetailsController: UIViewController {

    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var openMapsButton: UIButton!
    @IBOutlet weak var mapView: Map!
    @IBOutlet weak var rundownButton: UIButton!

    var firebox: FireBox?
    var locations: [Location] = []
    var nearbyLocations: [LocationDistance] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
        GoogleAnalyticsController.shared.trackScreen(name: "FireBoxDetailsController")
    }

    private func setupNavigationBar() {
        navigationController?.isNavigationBarHidden = false

        if #available(iOS 13.0, *) {
            navigationItem.rightBarButtonItem = UIBarButtonItem(image: UIImage(systemName: "drop.fill"),
                                                               style: .plain,
                                                               target: self,
                                                               action: #selector(fetchHydrants(_:)))
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Hydrants",
                                                               style: .done,
                                                               target: self,
                                                               action: #selector(fetchHydrants(_:)))
        }
    }

    private func setupViews() {
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
            addressLabel.textColor = .label
        } else {
            view.backgroundColor = .white
            addressLabel.textColor = .darkText
        }

        addressLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        addressLabel.adjustsFontForContentSizeCategory = true
        openMapsButton.setTitle("Directions", for: .normal)
        rundownButton.setTitle("Nearby", for: .normal)
        stylePrimaryButton(openMapsButton)
        styleSecondaryButton(rundownButton)
        mapView.addBorder(color: UIColor(white: 0.88, alpha: 1))

        guard let firebox = firebox else { return }
        title = "Box \(firebox.boxNumber)"
        addressLabel.text = firebox.address + "\n" + (firebox.borough ?? "")

        firebox.toCoordinates { [weak self] (coordinates) in
            if let coordinates = coordinates {
                self?.mapView.addMarker(toLocation: firebox, color: .blue)
                self?.mapView.setupMapRegion(startCoordinates: coordinates, radius: 1000)
            }
        }

        updateMap(withLocations: locations)
    }

    func color(forAnnotation annotation: MKAnnotation) -> UIColor {
        if annotation.title == "*" {
            return .yellow
        }
        return annotation.title ?? "" == firebox?.boxNumber ?? "" ? .blue : .red
    }

    func update(withBox firebox: FireBox, locations: [Location]) {
        self.firebox = firebox
        self.locations = locations
        calculateNearbyLocations()
        if isViewLoaded {
            setupViews()
        }
    }

    private func updateMap(withLocations locations: [Location]) {
        for location in locations {
            mapView.addMarker(toLocation: location, color: .red)
        }
    }

    private func calculateNearbyLocations() {

        guard  let firebox = firebox else { return }
        if isViewLoaded {
            rundownButton.setTitle("Loading nearby...", for: .normal)
            rundownButton.isEnabled = false
        }
        firebox.nearbyLocations(fromLocations: locations, maxLocations: 10) { [weak self] (nearbyLocations) in
            self?.nearbyLocations = nearbyLocations
            if self?.isViewLoaded == true {
                self?.rundownButton.isEnabled = true
                self?.rundownButton.setTitle(nearbyLocations.isEmpty ? "No Nearby" : "Nearby", for: .normal)
            }
        }
    }

    private func stylePrimaryButton(_ button: UIButton) {
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.layer.cornerRadius = 8
        button.layer.masksToBounds = true
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        button.backgroundColor = .systemRed
        button.setTitleColor(.white, for: .normal)
    }

    private func styleSecondaryButton(_ button: UIButton) {
        button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        button.titleLabel?.adjustsFontForContentSizeCategory = true
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemRed.cgColor
        button.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        button.backgroundColor = .clear
        button.setTitleColor(.systemRed, for: .normal)
        button.setTitleColor(.gray, for: .disabled)
    }

    //MARK: - Actions
    @IBAction func onDirections(_ sender: Any) {
        firebox?.toCoordinates({ [weak self] (coordinates) in
            guard let firebox = self?.firebox, let coordinates = coordinates else { return }
            let regionDistance: CLLocationDistance = 500
            let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates,
                                                                regionDistance,
                                                                regionDistance)
            let options = [
                MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: regionSpan.center),
                MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: regionSpan.span)
            ]

            let placemark = MKPlacemark(coordinate: coordinates, addressDictionary: nil)
            let mapItem = MKMapItem(placemark: placemark)
            mapItem.name = firebox.address
            MKMapItem.openMaps(with: [mapItem], launchOptions: options)
        })
    }

    @IBAction func onRundown(_ sender: Any) {
        if nearbyLocations.isEmpty {
            calculateNearbyLocations()
        }

        let nearbyViewController = NearbyLocationsViewController(locations: nearbyLocations)
        nearbyViewController.modalPresentationStyle = .overFullScreen
        nearbyViewController.modalTransitionStyle = .crossDissolve
        (presentedViewController ?? self).present(nearbyViewController, animated: true, completion: nil)
    }

    @objc private func onBack(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func fetchHydrants(_ sender: UIBarButtonItem) {
        if let lat = firebox?.latitude, let long = firebox?.longitude {
            let location = CLLocation(latitude: lat, longitude: long)
            APIController().fetchHydrantsNearLocation(location: location) { (hydrants) in
                for hydrant in hydrants {
                    self.mapView.mapView.addAnnotationToLocation(hydrant.location, title: "*", subtitle: nil, image: nil)
                }
            }

        }
    }
}

private class NearbyLocationsViewController: UIViewController {
    private let locations: [LocationDistance]
    private let dimmingView = UIView()
    private let panelView = UIView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let emptyLabel = UILabel()
    private let closeButton = UIButton(type: .system)

    init(locations: [LocationDistance]) {
        self.locations = locations
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        self.locations = []
        super.init(coder: aDecoder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        setupConstraints()
    }

    private func setupViews() {
        view.backgroundColor = .clear

        dimmingView.backgroundColor = UIColor.black.withAlphaComponent(0.62)
        dimmingView.alpha = 0
        dimmingView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(close)))
        view.addSubview(dimmingView)

        panelView.backgroundColor = nearbyPanelColor()
        panelView.layer.cornerRadius = 16
        panelView.layer.borderWidth = 1.5
        panelView.layer.borderColor = nearbyPanelBorderColor().cgColor
        panelView.layer.shadowColor = UIColor.black.cgColor
        panelView.layer.shadowOpacity = 0.28
        panelView.layer.shadowRadius = 24
        panelView.layer.shadowOffset = CGSize(width: 0, height: 14)
        panelView.layer.masksToBounds = false
        view.addSubview(panelView)

        titleLabel.text = "Nearby locations"
        titleLabel.font = UIFont.preferredFont(forTextStyle: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = nearbyPrimaryTextColor()
        panelView.addSubview(titleLabel)

        subtitleLabel.text = locations.isEmpty ? "Still loading. Try again in a moment." : "\(locations.count) closest firehouses and EMS stations"
        subtitleLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        subtitleLabel.adjustsFontForContentSizeCategory = true
        subtitleLabel.textColor = nearbySecondaryTextColor()
        subtitleLabel.numberOfLines = 0
        panelView.addSubview(subtitleLabel)

        closeButton.setTitle("Done", for: .normal)
        closeButton.titleLabel?.font = UIFont.preferredFont(forTextStyle: .headline)
        closeButton.tintColor = nearbyAccentColor()
        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)
        panelView.addSubview(closeButton)

        tableView.dataSource = self
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 92
        tableView.register(NearbyLocationCell.self, forCellReuseIdentifier: NearbyLocationCell.reuseIdentifier)
        panelView.addSubview(tableView)

        emptyLabel.text = "Nearby locations are not available yet."
        emptyLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        emptyLabel.textColor = nearbySecondaryTextColor()
        emptyLabel.textAlignment = .center
        emptyLabel.numberOfLines = 0
        emptyLabel.isHidden = !locations.isEmpty
        panelView.addSubview(emptyLabel)
    }

    private func setupConstraints() {
        dimmingView.translatesAutoresizingMaskIntoConstraints = false
        panelView.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        tableView.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false

        let guide = view.safeAreaLayoutGuide
        let tableHeight: CGFloat
        if locations.isEmpty {
            tableHeight = 120
        } else {
            tableHeight = min(max(CGFloat(locations.count) * 92, 240), 420)
        }

        NSLayoutConstraint.activate([
            dimmingView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmingView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmingView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmingView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            panelView.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            panelView.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            panelView.centerYAnchor.constraint(equalTo: guide.centerYAnchor),
            panelView.heightAnchor.constraint(lessThanOrEqualTo: guide.heightAnchor, multiplier: 0.82),

            titleLabel.topAnchor.constraint(equalTo: panelView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: panelView.leadingAnchor, constant: 20),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: closeButton.leadingAnchor, constant: -12),

            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -20),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -20),

            tableView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: 14),
            tableView.leadingAnchor.constraint(equalTo: panelView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: panelView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: panelView.bottomAnchor, constant: -12),
            tableView.heightAnchor.constraint(equalToConstant: tableHeight),

            emptyLabel.topAnchor.constraint(equalTo: tableView.topAnchor, constant: 24),
            emptyLabel.leadingAnchor.constraint(equalTo: panelView.leadingAnchor, constant: 24),
            emptyLabel.trailingAnchor.constraint(equalTo: panelView.trailingAnchor, constant: -24)
        ])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIView.animate(withDuration: 0.18) {
            self.dimmingView.alpha = 1
        }
    }

    @objc private func close() {
        dismiss(animated: true, completion: nil)
    }
}

extension NearbyLocationsViewController: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return locations.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: NearbyLocationCell.reuseIdentifier, for: indexPath) as! NearbyLocationCell
        cell.populate(with: locations[indexPath.row], rank: indexPath.row + 1)
        return cell
    }
}

private class NearbyLocationCell: UITableViewCell {
    static let reuseIdentifier = "NearbyLocationCell"

    private let cardView = UIView()
    private let rankLabel = UILabel()
    private let distanceLabel = UILabel()
    private let nameLabel = UILabel()
    private let addressLabel = UILabel()

    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupViews()
        setupConstraints()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupViews()
        setupConstraints()
    }

    private func setupViews() {
        selectionStyle = .none
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        cardView.backgroundColor = nearbyCardColor()
        cardView.layer.cornerRadius = 10
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = nearbySeparatorColor().cgColor
        contentView.addSubview(cardView)

        rankLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        rankLabel.adjustsFontForContentSizeCategory = true
        rankLabel.textAlignment = .center
        rankLabel.textColor = .white
        rankLabel.backgroundColor = nearbyAccentColor()
        rankLabel.layer.cornerRadius = 15
        rankLabel.layer.masksToBounds = true
        cardView.addSubview(rankLabel)

        distanceLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        distanceLabel.adjustsFontForContentSizeCategory = true
        distanceLabel.textColor = nearbyAccentColor()
        distanceLabel.textAlignment = .right
        cardView.addSubview(distanceLabel)

        nameLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        nameLabel.adjustsFontForContentSizeCategory = true
        nameLabel.textColor = nearbyPrimaryTextColor()
        nameLabel.numberOfLines = 0
        cardView.addSubview(nameLabel)

        addressLabel.font = UIFont.preferredFont(forTextStyle: .subheadline)
        addressLabel.adjustsFontForContentSizeCategory = true
        addressLabel.textColor = nearbySecondaryTextColor()
        addressLabel.numberOfLines = 0
        cardView.addSubview(addressLabel)
    }

    private func setupConstraints() {
        cardView.translatesAutoresizingMaskIntoConstraints = false
        rankLabel.translatesAutoresizingMaskIntoConstraints = false
        distanceLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        addressLabel.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 6),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -6),

            rankLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            rankLabel.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 14),
            rankLabel.widthAnchor.constraint(equalToConstant: 30),
            rankLabel.heightAnchor.constraint(equalToConstant: 30),

            distanceLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            distanceLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            distanceLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 58),

            nameLabel.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 14),
            nameLabel.leadingAnchor.constraint(equalTo: rankLabel.trailingAnchor, constant: 12),
            nameLabel.trailingAnchor.constraint(lessThanOrEqualTo: distanceLabel.leadingAnchor, constant: -8),

            addressLabel.topAnchor.constraint(equalTo: nameLabel.bottomAnchor, constant: 5),
            addressLabel.leadingAnchor.constraint(equalTo: nameLabel.leadingAnchor),
            addressLabel.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -14),
            addressLabel.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -14)
        ])
    }

    func populate(with locationDistance: LocationDistance, rank: Int) {
        let destination = locationDistance.destination
        rankLabel.text = "\(rank)"
        distanceLabel.text = String(format: "%.1f mi", locationDistance.distance / 1609.344)
        nameLabel.text = destination.name.isEmpty ? "Unnamed location" : destination.name
        addressLabel.text = destination.address.isEmpty ? destination.borough ?? "" : destination.address
    }
}

private func nearbyAccentColor() -> UIColor {
    if #available(iOS 13.0, *) {
        return .systemRed
    }
    return .red
}

private func nearbyPanelColor() -> UIColor {
    if #available(iOS 13.0, *) {
        return .systemGroupedBackground
    }
    return UIColor(white: 0.94, alpha: 1)
}

private func nearbyCardColor() -> UIColor {
    if #available(iOS 13.0, *) {
        return .systemBackground
    }
    return .white
}

private func nearbyPrimaryTextColor() -> UIColor {
    if #available(iOS 13.0, *) {
        return .label
    }
    return .darkText
}

private func nearbySecondaryTextColor() -> UIColor {
    if #available(iOS 13.0, *) {
        return .secondaryLabel
    }
    return .gray
}

private func nearbySeparatorColor() -> UIColor {
    if #available(iOS 13.0, *) {
        return .separator
    }
    return UIColor(white: 0.85, alpha: 1)
}

private func nearbyPanelBorderColor() -> UIColor {
    if #available(iOS 13.0, *) {
        return .opaqueSeparator
    }
    return UIColor(white: 0.70, alpha: 1)
}
