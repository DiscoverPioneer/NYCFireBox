import Foundation
import CoreLocation

typealias LocationCallback = (_ location: CLLocation?) -> Void
typealias CoordinatesCallback = (_ coordinates: CLLocationCoordinate2D?) -> Void
typealias NearbyLocationsCallback = (_ locations: [LocationDistance]) -> Void

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

    func geoCodeAddress(callback: @escaping LocationCallback) {
        let geoCoder = CLGeocoder()

        geoCoder.geocodeAddressString(fullAddress()) { [weak self] (placemarks, error) in
            if error == nil {
                callback(placemarks?.first?.location)
                self?.longitude = placemarks?.first?.location?.coordinate.longitude
                self?.latitude = placemarks?.first?.location?.coordinate.latitude
            } else {
                callback(nil)
            }
        }
    }

    func toLocation(_ callback: @escaping LocationCallback) {
        guard let longitude = longitude, let latitude = latitude else {
            geoCodeAddress(callback: { (location) in
                callback(location)
            })
            return
        }
        callback(CLLocation(latitude: latitude, longitude: longitude))
    }

    func toCoordinates(_ callback: @escaping CoordinatesCallback) {
        guard let longitude = longitude, let latitude = latitude else {
            geoCodeAddress(callback: { (location) in
                callback(location?.coordinate)
            })
            return
        }
        let coordinates = CLLocationCoordinate2DMake(Double(latitude),
                                                     Double(longitude))
        callback(coordinates)
    }

    func nearbyLocations(fromLocations locations: [Location], maxLocations: Int, callback: @escaping NearbyLocationsCallback ) {
        var distances: [LocationDistance] = []
        let taskGroup = DispatchGroup()

        toLocation({ (fireboxLocation) in
            guard let fireboxLocation = fireboxLocation else {
                callback([])
                return
            }

            for destinationLocation in locations {
                taskGroup.enter()
                destinationLocation.toLocation({ (location) in
                    taskGroup.leave()
                    guard let location = location else { return }
                    let distance = fireboxLocation.distance(from: location)
                    distances.append(LocationDistance(distance: distance, origin: self, destination: destinationLocation))
                })
            }

            taskGroup.notify(queue: DispatchQueue.main, work: DispatchWorkItem(block: {
                distances.sort { (location1, location2 ) -> Bool in
                    location1.distance < location2.distance
                }

                let array = distances.count > maxLocations ? Array(distances.prefix(maxLocations)) : distances
                callback(array)
            }))
        })
    }
}
