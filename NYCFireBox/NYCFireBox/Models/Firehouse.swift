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
                   latitude: latitude,
                   note: nil)
    }

    init(string: String) {
        let str = string.replacingOccurrences(of: "\"", with: "")
        let columns = str.components(separatedBy: ",")

        let name = columns[safe: 0] ?? ""
        let address = columns[safe: 1] ?? ""
        let latitude = Double(columns[safe: 2] ?? "")
        let longitude = Double(columns[safe: 3] ?? "")

        super.init(name: name,
                   address: address,
                   borough: nil,
                   area: nil,
                   longitude: longitude,
                   latitude: latitude,
                   note: nil)
    }
}
