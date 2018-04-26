import Foundation
import CoreLocation

class Location {
    var name: String
    var address: String
    var borough: String?
    var area: String?
    var longitude: Double?
    var latitude: Double?

    init(name: String, address: String, borough: String?, area: String?, longitude: Double?, latitude: Double?) {
        self.name = name
        self.longitude = longitude
        self.latitude = latitude
        self.address = address
        self.borough = borough
        self.area = area
    }

    func fullAddress() -> String {
        return address + (borough ?? "") + (area ?? "")
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
