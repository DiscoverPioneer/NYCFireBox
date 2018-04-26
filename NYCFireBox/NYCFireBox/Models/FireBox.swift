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

class FireBox: Location {
    var boxNumber: String

    init(string: String) {
        let columns = string.components(separatedBy: ",")
        self.boxNumber = columns[safe: 3] ?? ""
        let address = columns[safe: 4] ?? ""
        let borough = NYCBoroughs(rawValue: columns[safe: 2] ?? "")?.fullName ?? ""
        let longitude = Double(columns[safe: 0] ?? "")
        let latitude = Double(columns[safe: 1] ?? "")

        super.init(name: boxNumber,
                   address: address,
                   borough: borough,
                   area: nil,
                   longitude: longitude,
                   latitude: latitude)
    }
}
