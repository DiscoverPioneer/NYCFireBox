import Foundation

class EMSStation {
    var name: String
    var address: String
    var coordinates: Location
    var phone: String
    var fax: String
    var borough: String
    var area: String

    init(name: String,
         address: String,
         coordinates: Location,
         phone: String,
         fax: String,
         borough: String,
         area: String) {

        self.name = name
        self.address = address
        self.coordinates = coordinates
        self.phone = phone
        self.fax = fax
        self.borough = borough
        self.area = area
    }

    init(dictionary: [String: Any]) {
        self.name = dictionary["name"] as? String ?? ""
        self.address = dictionary["address"] as? String ?? ""
        self.coordinates = Location(name: dictionary["name"] as? String ?? "",
                                    coordinates: dictionary["coordinate"] as? String ?? "")
        self.phone = dictionary["phone"] as? String ?? ""
        self.fax = dictionary["fax"] as? String ?? ""
        self.borough = dictionary["borough"] as? String ?? ""
        self.area = dictionary["area"] as? String ?? ""
    }
}
