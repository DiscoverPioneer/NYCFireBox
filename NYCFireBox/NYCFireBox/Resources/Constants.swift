import Foundation

struct NetworkConstants {
    struct InfoURL {
        static let contact = "contact@pioneerapplications.com"
        static let website =  "http://pioneerapplications.com?ref=fireboxapp"
        static let liveIncidents = "https://itunes.apple.com/us/app/fire-buff/id592485608?mt=8"
        static let mobileMDT = "https://itunes.apple.com/us/app/mobile-mdt/id1251028336?mt=8"
        static let fdNewYork = "http://www.fdnewyork.com/"
    }

    struct Datasource {
        private static let baseURL = "http://pioneerapplications.com/AppResources/firebuff/"
        static let emsStations = baseURL + "EMS-Stations.plist"
        static let bronx = baseURL + "Bronx.plist"
        static let brooklyn = baseURL + "Brooklyn.plist"
        static let manhattan = baseURL + "Manhattan.plist"
        static let queens = baseURL + "Queens.plist"
        static let statenIsland = baseURL + "StatenIsland.plist"
    }

    struct UserDefaultsKeys {
        static let lastModifiedEMS = "lastModifiedEMS"
        static let lastModifiedBronx = "lastModifiedBronx"
        static let lastModifiedBrooklyn = "lastModifiedBrooklyn"
        static let lastModifiedManhattan = "lastModifiedManhattan"
        static let lastModifiedQueens = "lastModifiedQueens"
        static let lastModifiedStatenIsland = "lastModifiedStatenIsland"
    }
}

struct NYCCoordinates {
    static let longitude = -74.0060
    static let latitude = 40.7128
}
