import Foundation
import UIKit
import MapKit

class FireBoxDetailsController: UIViewController {

    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var openMapsButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var rundownButton: UIButton!

    var firebox: FireBox?
    var locations: [Location] = []

    override func viewDidLoad() {
        super.viewDidLoad()
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
        mapView.layer.borderColor = UIColor.gray.cgColor
        mapView.delegate = self

        guard let firebox = firebox else { return }
        title = "Box \(firebox.boxNumber)"
        addressLabel.text = firebox.address + "\n" + firebox.borough

        let pin = MKPointAnnotation()
        let coordinates = firebox.coordinates.toCoordinates()
        pin.title = String(describing: firebox.boxNumber)
        pin.coordinate = coordinates
        mapView.addAnnotation(pin)

        let radius: Double = 1000
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinates,
                                                                  radius * 1.5,
                                                                  radius * 1.5)
        mapView.setRegion(coordinateRegion, animated: true)
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
    }

    private func updateMap(withLocations locations: [Location]) {
        for location in locations {
            let pin = MKPointAnnotation()
            pin.title = String(describing: location.name)
            pin.coordinate = location.toCoordinates()
            mapView.addAnnotation(pin)
        }
    }

    //MARK: - Actions
    @IBAction func onDirections(_ sender: Any) {
        guard let firebox = firebox else { return }
        let locationCoordinates = firebox.coordinates.toCoordinates()
        let regionDistance: CLLocationDistance = 500
        let coordinates = CLLocationCoordinate2DMake(locationCoordinates.latitude, locationCoordinates.longitude)
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

    }

    @objc private func onBack(_ sender: UIBarButtonItem) {
        navigationController?.popViewController(animated: true)
    }
}

extension FireBoxDetailsController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "annotationReuseID")
        annotationView.markerTintColor = color(forAnnotation: annotation)
        annotationView.isEnabled = true
        annotationView.canShowCallout = true
        annotationView.leftCalloutAccessoryView = UILabel()
        return annotationView
    }
}
