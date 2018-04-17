import Foundation
import UIKit
import MapKit

class FireBoxCell: UITableViewCell {
    static let cellID = "FireBoxCellIdentifier"
    static let defaultHeight: CGFloat = 300

    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var mapView: MKMapView!

    func populate(withBox box: FireBox) {
        addressLabel.text = box.address + "\n" + box.borough
        mapView.layer.borderColor = UIColor.gray.cgColor

        let pin = MKPointAnnotation()
        pin.title = String(describing: box.boxNumber)
        pin.coordinate = box.location().coordinate
        mapView.addAnnotation(pin)

        let radius: Double = 500
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(box.location().coordinate,
                                                                  radius * 1.2, radius * 1.2)
        mapView.setRegion(coordinateRegion, animated: true)
    }

    override func prepareForReuse() {
        mapView.removeAnnotations(mapView.annotations)
    }
}
