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

    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupNavigationBar()
        setupViews()
        GoogleAnalyticsController.shared.trackScreen(name: "FireBoxDetailsController")
    }

    private func setupNavigationBar() {
        navigationController?.isNavigationBarHidden = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Back",
                                                           style: .done,
                                                           target: self,
                                                           action: #selector(onBack(_:)))
    }

    private func setupViews() {
        mapView.addBorder(color: .gray)

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
        return annotation.title ?? "" == firebox?.boxNumber ?? "" ? .blue : .red
    }

    func update(withBox firebox: FireBox, locations: [Location]) {
        self.firebox = firebox
        self.locations.append(contentsOf: locations)
        calculateNearbyLocations()
    }

    private func updateMap(withLocations locations: [Location]) {
        for location in locations {
            mapView.addMarker(toLocation: location, color: .red)
        }
    }

    private func calculateNearbyLocations() {

        guard  let firebox = firebox else { return }
        firebox.nearbyLocations(fromLocations: locations, maxLocations: 10) { [weak self] (nearbyLocations) in
            self?.nearbyLocations = nearbyLocations
        }
    }

    //MARK: - Actions
    @IBAction func onDirections(_ sender: Any) {
        firebox?.toCoordinates({ [weak self] (coordinates) in
            guard let firebox = self?.firebox, let coordinates = coordinates else { return }
            let regionDistance: CLLocationDistance = 500
            let regionSpan = MKCoordinateRegionMakeWithDistance(coordinates, regionDistance, regionDistance)
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
        let alertController = UIAlertController()
        alertController.title = "Nearby locations"
        var message = ""
        for location in nearbyLocations {
            message.append(contentsOf: location.destination.name + "\n\n")
        }
        alertController.message = message
        let okAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        (presentedViewController ?? self).present(alertController, animated: true, completion: nil)
    }

    @objc private func onBack(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
}

