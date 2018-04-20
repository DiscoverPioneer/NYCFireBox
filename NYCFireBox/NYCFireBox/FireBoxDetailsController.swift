import Foundation
import UIKit
import MapKit

class FireBoxDetailsController: UIViewController {

    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var openMapsButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var rundownButton: UIButton!

    var firebox: FireBox?

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

        let radius: Double = 500
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinates,
                                                                  radius * 1.5,
                                                                  radius * 1.5)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    func color(forAnnotation annotation: MKAnnotation) -> UIColor {
        return annotation.title ?? "" == firebox?.boxNumber ?? "" ? .blue : .red
    }

    func update(withBox firebox: FireBox) {
        self.firebox = firebox
    }

    //MARK: - Actions
    @IBAction func onDirections(_ sender: Any) {

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
        return annotationView
    }
}
