import Foundation
import CoreLocation

class Location {
    var name: String
    var longitude: Double
    var latitude: Double

    init(name: String,longitude: Double, latitude: Double) {
        self.name = name
        self.longitude = longitude
        self.latitude = latitude
    }

    init(name: String, coordinates: String) {
        self.name = name
        let substrings = coordinates.split(separator: ",")
        self.latitude = Double(substrings.first?.replacingOccurrences(of: " ", with: "") ?? "") ?? 0
        self.longitude = Double(substrings.last?.replacingOccurrences(of: " ", with: "") ?? "") ?? 0
    }

    func toLocation() -> CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }

    func toCoordinates() -> CLLocationCoordinate2D {
        let coordinates = self.toLocation().coordinate
        return CLLocationCoordinate2DMake(coordinates.latitude,
                                          coordinates.longitude)
    }
}
