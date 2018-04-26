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
        addressLabel.text = firebox.address + "\n" + firebox.borough

        if let location = firebox.coordinates, let coordinates = location.toCoordinates() {
            mapView.addMarker(toLocation: location, color: .blue)
            mapView.setupMapRegion(startCoordinates: coordinates, radius: 1000)
        }
        updateMap(withLocations: locations)
    }

    func color(forAnnotation annotation: MKAnnotation) -> UIColor {
        return annotation.title ?? "" == firebox?.boxNumber ?? "" ? .blue : .red
    }

    func update(withBox firebox: FireBox, firehouses: [Firehouse], emsStations: [EMSStation]) {
        self.firebox = firebox

        for firehouse in firehouses {
            self.locations.append(firehouse.coordinates)
        }

        for emsStation in emsStations {
            self.locations.append(emsStation.coordinates)
        }
        calculateNearbyLocations()
    }

    private func updateMap(withLocations locations: [Location]) {
        for location in locations {
            mapView.addMarker(toLocation: location, color: .red)
        }
    }

    private func calculateNearbyLocations() {
        guard  let firebox = firebox else { return }
        var distances: [LocationDistance] = []
        for location in locations {
            if let fireboxLocation = firebox.coordinates?.toLocation(),
                let destinationLocation = location.toLocation(),
                let fireboxCoordinates = firebox.coordinates {
                let distance = fireboxLocation.distance(from: destinationLocation)
                distances.append(LocationDistance(distance: distance, origin: fireboxCoordinates, destination: location))
            }
        }

        distances.sort { (location1, location2 ) -> Bool in
            location1.distance < location2.distance
        }

        self.nearbyLocations = Array(distances.prefix(10))
    }

    //MARK: - Actions
    @IBAction func onDirections(_ sender: Any) {
        guard let firebox = firebox, let coordinates = firebox.coordinates?.toCoordinates() else { return }
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

