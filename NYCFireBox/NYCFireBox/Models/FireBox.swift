import Foundation
import CoreLocation

enum NYCBoroughs: String {
    // Borough codes
    case brooklyn = "B"
    case manhattan = "M"
    case bronx = "X"
    case queens = "Q"
    case statenIsland = "R"

    var fullName: String {
        switch self {
        case .brooklyn: return "Brooklyn"
        case .manhattan: return "Manhattan"
        case .bronx: return "Bronx"
        case .queens: return "Queens"
        case .statenIsland: return "Staten Island"
        }
    }
}

class FireBox {
    var coordinates: Location?
    var boxNumber: String
    var address: String
    var borough: String

    init(coordinates: Location?, boxNumber: String, address: String, borough: String) {
        self.boxNumber = boxNumber
        self.address = address
        self.borough = borough
        self.coordinates = coordinates
    }

    init(string: String) {
        let columns = string.components(separatedBy: ",")
        self.coordinates = Location(name: columns[safe: 4] ?? "",
                                    longitude: Double(columns[safe: 0] ?? ""),
                                    latitude: Double(columns[safe: 1] ?? ""))
        self.address = columns[safe: 4] ?? ""
        self.boxNumber = columns[safe: 3] ?? ""
        self.borough = columns[safe: 2] ?? ""
    }
}
