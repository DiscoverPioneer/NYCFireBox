//
//  APIController+OpenData.swift
//  CityHydrants
//
//  Created by Phil Scarfi on 5/9/19.
//  Copyright © 2019 Pioneer Mobile Applications, LLC. All rights reserved.
//

import Foundation
import CoreLocation

extension APIController {
    func fetchHydrantsNearLocation(location: CLLocation, completion: @escaping (_ hydrants: [HydrantLocation]) -> Void) {
        let whereClause = "within_circle(the_geom,\(location.coordinate.latitude),\(location.coordinate.longitude),500)"
        makeNonTokenRequest(type: .get, url: "https://data.cityofnewyork.us/resource/5bgh-vtsn.json", parameters: ["$$app_token":"5mWUpsZbNPAWuRgUpk5Kdo5rJ","$where":whereClause]) { (success, error, data) in
            
            var allHydrants = [HydrantLocation]()
            if let rawDataArray = data?["data"] as? [[String:Any?]] {
                for rawData in rawDataArray {
                    if let boro = rawData["boro"] as? String, let boroNumber = Int(boro), let latitude = Double(rawData["latitude"] as? String ?? "-"), let longitude = Double(rawData["longitude"] as? String ?? "-") {
                        let latDegrees = CLLocationDegrees(floatLiteral: latitude)
                        let longDegrees = CLLocationDegrees(floatLiteral: longitude)
                        allHydrants.append(HydrantLocation(location: CLLocation(latitude: latDegrees, longitude: longDegrees), boro: boroNumber))
                    }
                }
            }
            completion(allHydrants)
            print("All Hydrants = \(allHydrants)")
        }
    }
}

struct HydrantLocation {
    let location: CLLocation
    let boro: Int
}
