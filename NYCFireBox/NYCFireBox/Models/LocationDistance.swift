import Foundation
import CoreLocation

struct LocationDistance {
    var distance: CLLocationDistance
    var origin: Location
    var destination: Location

    init(distance: CLLocationDistance, origin: Location, destination: Location) {
        self.distance = distance
        self.origin = origin
        self.destination = destination
    }
}
