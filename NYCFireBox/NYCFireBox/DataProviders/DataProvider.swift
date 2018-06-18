import Foundation

class DataProvider {

    class func getFireBoxes(_ callback: (_ fireboxes: [FireBox]) -> ()) {
        var fireBoxes: [FireBox] = []
        guard let filePath = Bundle.main.path(forResource: "Fire Boxes", ofType: "csv") else {
            callback([])
            return
        }
        let contents = try? String(contentsOfFile: filePath, encoding: .utf8)
        let rows = contents?.components(separatedBy: "\n")
        for row in rows ?? [] {
            let firebox = FireBox(string: row)
            if firebox.name.contains("LGA - AIRPORT EMERGENCY RESPONSE") || firebox.boxNumber == "0037" || firebox.boxNumber == "37" {
                print("Found box: \(row)")
            }
            fireBoxes.append(firebox)
        }
        callback(fireBoxes)
    }

    class func getFirehouses(forBorough borough: NYCBoroughs, completionHandler:  @escaping ([Firehouse]) -> Void) {
        var path = ""
        switch borough {
        case .bronx: path = NetworkConstants.Datasource.bronx
        case .brooklyn: path = NetworkConstants.Datasource.brooklyn
        case .manhattan: path = NetworkConstants.Datasource.manhattan
        case .queens: path = NetworkConstants.Datasource.queens
        case .statenIsland: path = NetworkConstants.Datasource.statenIsland
        }

        if let fromURL = URL(string: path) {
            FileUpdater().syncFileFrom(url: fromURL, andSaveAs: borough.fullName) {
                let firehouses = DataProvider.retrieveFirehousesFromFile(filename: borough.fullName)
                DispatchQueue.main.async {
                    completionHandler(firehouses)
                }
            }
        } else {
            completionHandler(getLocalFirehouses(forBorough: borough))
        }
    }

    class func getEMSStations(completionHandler: @escaping ([EMSStation]) -> Void) {
        if let fromURL = URL(string: NetworkConstants.Datasource.emsStations) {
            FileUpdater().syncFileFrom(url: fromURL, andSaveAs: "EMS-Stations") {
                let firehouses = DataProvider.retrieveEMSStationsFromFile(filename: "EMS-Stations")
                DispatchQueue.main.async {
                    completionHandler(firehouses)
                }
            }
        } else {
            completionHandler(getLocalEMSStations())
        }
    }

    private class func getLocalFirehouses(forBorough borough: NYCBoroughs) -> [Firehouse] {
        var firehouses: [Firehouse] = []
        if let path = Bundle.main.path(forResource: borough.fullName , ofType: "plist") {
            let queensStations = NSArray(contentsOfFile: path) as? [[String: Any]] ?? []
            for station in queensStations {
                firehouses.append(Firehouse(dictionary: station))
            }
        }
        return firehouses
    }

    private class func getLocalEMSStations() -> [EMSStation] {
        var emsStations: [EMSStation] = []
        guard let path = Bundle.main.path(forResource: "EMS-Stations", ofType: "plist") else { return emsStations }
        let EMSStations = NSArray(contentsOfFile: path) as? [[String: Any]] ?? []
        for station in EMSStations {
            emsStations.append(EMSStation(dictionary: station))
        }
        return emsStations
    }

    private class func loadData(fromURL url: URL, to localUrl: URL, completionHandler: @escaping () -> ()) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        let task = session.downloadTask(with: request) { (tempURL, response, error) in
            if error == nil, tempURL != nil  {
                saveFile(toURL: localUrl.absoluteString, fromURL: tempURL!)
            }
            completionHandler()
        }
        task.resume()
    }

    private class func saveFile(toURL url: String, fromURL tempURL: URL) {
        let fileManager = FileManager.default
        let path = URL(fileURLWithPath: url)
        do {
            try _ = fileManager.replaceItemAt(path, withItemAt: tempURL, backupItemName: nil, options: .usingNewMetadataOnly)
        } catch {
            return
        }
    }

    private class func getLastModifiedDate(urlString: String,
                                      currentVersionDate: Date,
                                      completionHandler: @escaping ((_ shouldDownload: Bool) -> Void)) {
        guard let url = URL(string: urlString) else { completionHandler(false); return }

        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"

        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, error) in
            if error != nil {
                completionHandler(false)
                return
            }

            if let response = response as? HTTPURLResponse {
                if let lastModified = response.allHeaderFields["Last-Modified"] as? String {
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "E, d MMM yyyy HH:mm:ss Z"
                    let lastModifiedDate = dateFormatter.date(from: lastModified) ?? Date()
                    completionHandler(lastModifiedDate > currentVersionDate)
                    return
                }
            }
            completionHandler(false)
        })
        task.resume()
    }

    class func fileModificationDate(path: String) -> Date? {
        guard let url = URL(string: path) else { return nil }
        do {
            let attr = try FileManager.default.attributesOfItem(atPath: url.path)
            return attr[FileAttributeKey.modificationDate] as? Date
        } catch {
            return nil
        }
    }
}

extension DataProvider {
    class func retrieveFirehousesFromFile(filename: String) -> [Firehouse] {
        var firehouses = [Firehouse]()
        var url: URL?
        
        //Check if file exists in documents, else pull from bundle
        if let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileLocation = documentsUrl.appendingPathComponent("/files/\(filename).plist", isDirectory: false)
            if FileManager.default.fileExists(atPath: fileLocation.path) {
                url = fileLocation
                print("Using File URL, not bundle")
            }
        }
        
        if url == nil {
            url = Bundle.main.url(forResource: filename, withExtension: "plist")
        }
        if let URL = url {
            if let plist = NSArray(contentsOf: URL) as? [[String:String]] {
                for dict in plist {
                    firehouses.append(Firehouse(dictionary: dict))
                }
            } else {
                print("Not a valid plist type")
            }
        } else {
            print("NOt a valid URL")
        }
        return firehouses
    }
    
    class func retrieveEMSStationsFromFile(filename: String) -> [EMSStation] {
        var firehouses = [EMSStation]()
        var url: URL?
        
        //Check if file exists in documents, else pull from bundle
        if let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
            let fileLocation = documentsUrl.appendingPathComponent("/files/\(filename).plist", isDirectory: false)
            if FileManager.default.fileExists(atPath: fileLocation.path) {
                url = fileLocation
                print("Using File URL, not bundle")
                
            }
        }
        
        if url == nil {
            url = Bundle.main.url(forResource: filename, withExtension: "plist")
        }
        if let URL = url {
            if let plist = NSArray(contentsOf: URL) as? [[String:String]] {
                for dict in plist {
                    firehouses.append(EMSStation(dictionary: dict))
                }
            } else {
                print("Not a valid plist type")
            }
        } else {
            print("NOt a valid URL")
        }
        return firehouses
    }
}
