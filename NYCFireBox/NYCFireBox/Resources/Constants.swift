import Foundation

struct LocationURL {
    var name: String
    var url: String

    init(name: String, url: String) {
        self.name = name
        self.url = url
    }
}

struct Constants {
    let baseURL: String
    let longitude: Double
    let latitude: Double
    let fireboxFilename: String

    var locationsURL: [LocationURL]
    var emsStations: LocationURL?

    init() {
        let buindleID = Bundle.main.bundleIdentifier
        let path = Bundle.main.path(forResource: "Constants", ofType: "plist")
        let constants = NSDictionary(contentsOfFile: path!)
        let values = constants?.value(forKey: buindleID!) as! [String: AnyObject]

        baseURL = values["baseURL"] as! String
        longitude = values["baseCoordinates"]!["longitude"] as! Double
        latitude = values["baseCoordinates"]!["latitude"] as! Double
        fireboxFilename = values["fireboxFilename"] as! String
        
        locationsURL = []
        let locationsArray = values["locations"] as! [[String: Any]]
        for location in locationsArray {
            let newLocation = LocationURL(name: location["name"] as! String, url: baseURL+(location["url"] as! String))
            locationsURL.append(newLocation)
        }

        if let stations = values["emsStations"] as? [String: Any] {
            emsStations = LocationURL(name: stations["name"] as! String, url: stations["url"] as! String)
        }
    }
}

struct NetworkConstants {
    struct InfoURL {
        static let contact = "contact@pioneerapplications.com"
        static let website =  "http://pioneerapplications.com?ref=fireboxapp"
        static let liveIncidents = "https://itunes.apple.com/us/app/fire-buff/id592485608?mt=8"
        static let mobileMDT = "https://itunes.apple.com/us/app/mobile-mdt/id1251028336?mt=8"
        static let fdNewYork = "http://www.fdnewyork.com/"
        static let share = "https://itunes.apple.com/us/app/nycfirebox/id1377737408?mt=8&ign-mpt=uo%3D2"

    }
}

