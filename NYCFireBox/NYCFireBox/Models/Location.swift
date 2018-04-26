import Foundation
import CoreLocation

class Location {
    var name: String
    var longitude: Double?
    var latitude: Double?

    init(name: String, longitude: Double?, latitude: Double?) {
        self.name = name
        self.longitude = longitude
        self.latitude = latitude
    }

    init(name: String, coordinates: String) {
        self.name = name
        let substrings = coordinates.split(separator: ",")
        self.latitude = Double(substrings.first?.replacingOccurrences(of: " ", with: "") ?? "")
        self.longitude = Double(substrings.last?.replacingOccurrences(of: " ", with: "") ?? "")
    }

    func toLocation() -> CLLocation? {
        guard let longitude = longitude, let latitude = latitude else { return nil }
        return CLLocation(latitude: latitude, longitude: longitude)
    }

    func toCoordinates() -> CLLocationCoordinate2D? {
        guard let coordinates = self.toLocation()?.coordinate else { return nil }
        return CLLocationCoordinate2DMake(coordinates.latitude,
                                          coordinates.longitude)
    }
}
