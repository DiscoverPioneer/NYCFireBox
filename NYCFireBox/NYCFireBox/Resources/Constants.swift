import Foundation

struct LocationURL {
    var name: String
    var url: String

    init(name: String, url: String) {
        self.name = name
        self.url = url
    }
}

enum AppLocation {
    case Boston
    case NYC
}

struct Constants {
    let googleAnalyticsKey: String?
    let oneSignalKey: String?

    let appLocation: AppLocation
    let baseURL: String
    let longitude: Double
    let latitude: Double
    let fireboxFilename: String


    let shareURL: String?
    let contactURL: String?
    let websiteURL: String?

    let linkedAppURL: String?
    let liveincidentsURL: String?
    let firedepURL: String?

    var locationsURL: [LocationURL]
    var emsStations: LocationURL?

    init() {
        let bundleID = Bundle.main.bundleIdentifier
        let path = Bundle.main.path(forResource: "Constants", ofType: "plist")
        let constants = NSDictionary(contentsOfFile: path!)
        let values = constants?.value(forKey: bundleID!) as! [String: AnyObject]

        switch bundleID {
        case "com.Pioneer.BostonFireBox": appLocation = .Boston
        case "com.Pioneer.NYCFireBox": appLocation = .NYC
        default: appLocation = .NYC
        }

        googleAnalyticsKey = values["googleAnalytics"] as? String
        oneSignalKey = values["oneSignal"] as? String

        baseURL = values["baseURL"] as! String
        longitude = values["baseCoordinates"]!["longitude"] as! Double
        latitude = values["baseCoordinates"]!["latitude"] as! Double
        fireboxFilename = values["fireboxFilename"] as! String

        shareURL = values["shareURL"] as? String
        contactURL = values["contactURL"] as? String
        websiteURL = values["websiteURL"] as? String
        linkedAppURL = values["linkedAppURL"] as? String
        firedepURL = values["firedepURL"] as? String
        liveincidentsURL = values["liveIncidents"] as? String

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

