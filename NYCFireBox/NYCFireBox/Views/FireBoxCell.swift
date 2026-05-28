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
        addressLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        addressLabel.adjustsFontForContentSizeCategory = true
        if #available(iOS 13.0, *) {
            addressLabel.textColor = .label
            contentView.backgroundColor = .systemBackground
            mapView.layer.borderColor = UIColor.separator.cgColor
        } else {
            addressLabel.textColor = .darkText
            contentView.backgroundColor = .white
            mapView.layer.borderColor = UIColor.lightGray.cgColor
        }
        mapView.layer.borderWidth = 1
        mapView.layer.cornerRadius = 8
        mapView.layer.masksToBounds = true
        mapView.delegate = self
        locationUnavailableLabel.isHidden = true
        locationUnavailableLabel.layer.cornerRadius = 8
        locationUnavailableLabel.layer.masksToBounds = true
        locationUnavailableLabel.font = UIFont.preferredFont(forTextStyle: .headline)

        box.toCoordinates { [weak self] (coordinates) in
            if let coordinates = coordinates {
                let pin = MKPointAnnotation()
                pin.title = String(describing: box.boxNumber)
                pin.coordinate = coordinates
                self?.mapView.addAnnotation(pin)

                let radius: Double = 500
                let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinates,
                                                                          radius * 1.2,
                                                                          radius * 1.2)
                self?.mapView.setRegion(coordinateRegion, animated: true)
            } else {
                self?.locationUnavailableLabel.isHidden = false
//                self?.isUserInteractionEnabled = false
            }
        }
    }

    override func prepareForReuse() {
        super.prepareForReuse()
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
