import Foundation
import UIKit
import MapKit

class FireBoxCell: UITableViewCell {
    static let cellID = "FireBoxCellIdentifier"
    static let defaultHeight: CGFloat = 300

    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var locationUnavailableLabel: UILabel!
    
    func populate(withBox box: FireBox) {
        addressLabel.text = box.address + "\n" + (box.borough ?? "")
        mapView.layer.borderColor = UIColor.gray.cgColor
        mapView.delegate = self
        locationUnavailableLabel.isHidden = true

        box.toCoordinates { [weak self] (coordinates) in
            if let coordinates = coordinates {
                let pin = MKPointAnnotation()
                pin.title = String(describing: box.boxNumber)
                pin.coordinate = coordinates
                self?.mapView.addAnnotation(pin)

                let radius: Double = 500
                let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinates,
                                                                          radius * 1.2, radius * 1.2)
                self?.mapView.setRegion(coordinateRegion, animated: true)
            } else {
                self?.locationUnavailableLabel.isHidden = false
//                self?.isUserInteractionEnabled = false
            }
        }
    }

    override func prepareForReuse() {
        locationUnavailableLabel.isHidden = true
        mapView.removeAnnotations(mapView.annotations)
    }
}

extension FireBoxCell: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let annotationView = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: "annotationReuseID")
        annotationView.markerTintColor = .blue
        return annotationView
    }
}
