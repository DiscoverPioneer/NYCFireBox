import Foundation

class Firehouse: Location {
    init(dictionary: [String: Any]) {
        let coordinates = dictionary["coordinate"] as? String ?? ""
        let substrings = coordinates.split(separator: ",")
        let latitude = Double(substrings.first?.replacingOccurrences(of: " ", with: "") ?? "")
        let longitude = Double(substrings.last?.replacingOccurrences(of: " ", with: "") ?? "")
        
        super.init(name: dictionary["name"] as? String ?? "",
                   address: dictionary["address"] as? String ?? "",
                   borough: nil,
                   area: nil,
                   longitude: longitude,
                   latitude: latitude)
    }
}
