import Foundation

class Firehouse {
    var name: String
    var address: String
    var coordinates: Location

    init(name: String, address: String, coordinates: Location) {
        self.name = name
        self.address = address
        self.coordinates = coordinates
    }

    init(dictionary: [String: Any]) {
        self.name = dictionary["name"] as? String ?? ""
        self.address = dictionary["address"] as? String ?? ""
        self.coordinates = Location(name: dictionary["name"] as? String ?? "",
                                    coordinates: dictionary["coordinate"] as? String ?? "")
    }
}
