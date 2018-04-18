import Foundation
import CoreLocation

struct Location {
    var longitude: Double
    var latitude: Double

    init(longitude: Double, latitude: Double) {
        self.longitude = longitude
        self.latitude = latitude
    }

    init(string: String) {
        let substrings = string.split(separator: ",")
        print("Substrings \(substrings)")
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
