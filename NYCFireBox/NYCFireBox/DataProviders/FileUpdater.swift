//
//  FileUpdater.swift
//  FireBuff
//
//  Created by Phil Scarfi on 2/14/17.
//  Copyright © 2017 Pioneer Mobile Applications. All rights reserved.
//

import Foundation

public class FileUpdater {

    let fileDateFormatter = DateFormatter()
    let SaveToURL = URL(string: "/files/")!
    public func lastModDateForURL(url: URL, completion:@escaping (_ lastModDate: Date?) -> Void) {
        fileDateFormatter.dateFormat = "EEE',' dd MMM yyyy HH':'mm':'ss 'GMT'"
        let request = NSMutableURLRequest(url: url)
        let session = URLSession.shared
        request.httpMethod = "HEAD"
        
        let task = session.dataTask(with: request as URLRequest, completionHandler: {data, response, error -> Void in
            
            if let httpUrlResponse = response as? HTTPURLResponse
            {
                if let error = error {
                    print("Error Occurred: \(error.localizedDescription)")
                    completion(nil)
                } else {
                    if let dateStr = httpUrlResponse.allHeaderFields["Last-Modified"] as? String, let date = self.fileDateFormatter.date(from: dateStr) {
                            completion(date)
                    } else {
                        completion(nil)
                    }
                }
            } else {
                completion(nil)
            }
        })
        
        task.resume()
    }
    
    
    public func syncFileFrom(url: URL, andSaveAs fileName: String, completion:@escaping () -> Void) {
        let defaults = UserDefaults.standard
        lastModDateForURL(url: url) { (date) in
            if let date = date, defaults.object(forKey: "\(fileName)_MOD_KEY") as? Date != date {
                print("Updating the Bronx")
                    Downloader.load(filename: fileName, url: url, completion: { (success) in
                        print("UPDATE COMPLETE, success: \(success)")
                        if success {
                            defaults.set(date, forKey: "\(fileName)_MOD_KEY")
                        }
                        completion()
                    })
            } else {
                completion()
            }
        }
    }
}


class Downloader {
    class func load(filename: String, url: URL, completion: @escaping (_ success: Bool) -> ()) {
        let sessionConfig = URLSessionConfiguration.default
        let session = URLSession(configuration: sessionConfig)
        let request = URLRequest(url: url)
        
        let task = session.downloadTask(with: request) { (tempLocalUrl, response, error) in
            if let tempLocalUrl = tempLocalUrl, error == nil {
                // Success
                if let statusCode = (response as? HTTPURLResponse)?.statusCode {
                    print("Success: \(statusCode)")
                }
                
                do {
                    if let documentsUrl =  FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first {
                        let downloadLocation = documentsUrl.appendingPathComponent("/files/\(filename).plist", isDirectory: false)
                        if FileManager.default.fileExists(atPath: downloadLocation.path) {
                            try FileManager.default.removeItem(at: downloadLocation)
                        } else {
                            try FileManager.default.createDirectory(at: documentsUrl.appendingPathComponent("/files", isDirectory: true), withIntermediateDirectories: true, attributes: nil)
                        }
                        try FileManager.default.copyItem(at: tempLocalUrl, to: downloadLocation)
                        completion(true)
                    }
                } catch (let writeError) {
                    print("error writing file : \(writeError)")
                    completion(false)
                }
                
            } else {
                print("Failure: %@", error?.localizedDescription ?? "")
                completion(false)
            }
        }
        task.resume()
    }
}
