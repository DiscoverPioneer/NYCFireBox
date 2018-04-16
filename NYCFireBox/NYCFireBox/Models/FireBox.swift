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
    var longitude: Double
    var latitude: Double
    var boxNumber: String
    var address: String
    var borough: String

    init(longitude: Double, latitude: Double, boxNumber: String, address: String, borough: String) {
        self.boxNumber = boxNumber
        self.address = address
        self.longitude = longitude
        self.latitude = latitude
        self.borough = borough
    }

    init(string: String) {
        let columns = string.components(separatedBy: ",")
        self.longitude = Double(columns[safe: 0] ?? "") ?? 0
        self.latitude = Double(columns[safe: 1] ?? "") ?? 0 
        self.address = columns[safe: 3] ?? ""

        let number = columns[safe: 2] ?? ""
        self.boxNumber = "\(number[number.index(after: number.startIndex)...])"
        self.borough = NYCBoroughs(rawValue: "\(number[number.startIndex])")?.fullName ?? ""
    }

    func location() -> CLLocation {
        return CLLocation(latitude: latitude, longitude: longitude)
    }
}
