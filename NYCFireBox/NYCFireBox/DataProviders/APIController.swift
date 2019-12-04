//
//  APIController.swift
//  SavePop
//
//  Created by Phil Scarfi on 8/11/18.
//  Copyright © 2018 Pioneer Mobile Applications, LLC. All rights reserved.
//

import Foundation
import Alamofire

struct APIConstants {
    
    enum ErrorType {
        case unknown
        case custom
        case missingCredentials
        case invalidCredentials
        func error(message: String? = nil) -> Error {
            return Error(type: self, message: message)
        }
    }
    
    struct Error {
        let type: ErrorType
        let message: String?
        
        init(type: ErrorType, message: String? = nil) {
            self.type = type
            self.message = message
        }
    }
    
    struct Keys {
        static let error = "error"
    }
    
    //MARK: - ENDPOINTS
    static let baseURL = ""//Constants.constantForKey(key: ConfigKeys.apiBaseURI) as! String
    
}


public class APIController {
    var email: String?
    var token: String?
    
    init(email: String? = nil, token: String? = nil) {
        self.email = email
        self.token = token
    }
    
    fileprivate func request(type: HTTPMethod, url: String, parameters: [String:Any?]?, headers: [String:String]? = nil, completion: @escaping(_ success: Bool, _ error: APIConstants.Error?, _ data: [String:Any]?) -> Void) {
        var newParams = [String:Any]()
        if let parameters = parameters {
            for (key, value) in parameters {
                if value != nil {
                    newParams[key] = value!
                } else {
                    newParams[key] = NSNull()
                }
            }
        }
        print("Preparing request to: \(url)\n With parameterse: \(newParams)")
        Alamofire.request(url, method: type, parameters: newParams, encoding: URLEncoding.default, headers: headers).responseJSON { (response) in
            guard let statusCode = response.response?.statusCode else {
                completion(false, APIConstants.ErrorType.unknown.error(), nil)
                return
            }
            var data = (response.result.value as? [String:Any])
            print("Made request: Status Code = \(statusCode). Data=\(String(describing: data))")
            
            if data == nil {
                data = ["data":response.result.value as? [[String:Any]] ?? [:]]
            }
            if let data = data, let error = data[APIConstants.Keys.error] as? String {
                //  print("Made Request:\nURL:\(url)\nParameteres:\(parameters)\nError: \(error)")
                completion(false, APIConstants.ErrorType.custom.error(message: error), data)
                return
            }
            // print("Made Request:\nURL:\(url)\nParameteres:\(parameters)\nData: \(data)")
            completion(response.result.isSuccess || statusCode == 200, nil, data)
        }
    }
    
    func makeRequest(type: HTTPMethod, url: String, parameters: [String:Any?]?, completion: @escaping(_ success: Bool, _ error: APIConstants.Error?, _ data: [String:Any]?) -> Void) {
        guard let email = email, let token = token else {
            completion(false, APIConstants.Error(type: .missingCredentials), nil)
            return
        }
        let credentialData = "\(email):\(token)".data(using: String.Encoding.utf8)!
        let base64Credentials = credentialData.base64EncodedString(options: [])
        let headers = ["Authorization": "Basic \(base64Credentials)"]
        
        request(type: type, url: url, parameters: parameters, headers: headers, completion: completion)
    }
    
    func makeNonTokenRequest(type: HTTPMethod, url: String, parameters: [String:Any?]?, completion: @escaping(_ success: Bool, _ error: APIConstants.Error?, _ data: [String:Any]?) -> Void) {
        request(type: type, url: url, parameters: parameters, completion: completion)
    }
}
