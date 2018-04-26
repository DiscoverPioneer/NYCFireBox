import Foundation

class EMSStation: Location {
    var phone: String
    var fax: String

    init(name: String,
         address: String,
         longitude: Double,
         latitude: Double,
         phone: String,
         fax: String,
         borough: String,
         area: String) {
        self.phone = phone
        self.fax = fax
        super.init(name: name,
                   address: address,
                   borough: borough,
                   area: area,
                   longitude: longitude,
                   latitude: latitude)
    }

    init(dictionary: [String: Any]) {
        self.phone = dictionary["phone"] as? String ?? ""
        self.fax = dictionary["fax"] as? String ?? ""

        let coordinates = dictionary["coordinate"] as? String ?? ""
        let substrings = coordinates.split(separator: ",")
        let latitude = Double(substrings.first?.replacingOccurrences(of: " ", with: "") ?? "")
        let longitude = Double(substrings.last?.replacingOccurrences(of: " ", with: "") ?? "")
        
        super.init(name: dictionary["name"] as? String ?? "",
                   address: dictionary["address"] as? String ?? "",
                   borough: dictionary["borough"] as? String,
                   area: dictionary["area"] as? String,
                   longitude: longitude,
                   latitude: latitude)
    }
}
