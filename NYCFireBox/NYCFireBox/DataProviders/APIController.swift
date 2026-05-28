//
//  APIController.swift
//  SavePop
//
//  Created by Phil Scarfi on 8/11/18.
//  Copyright © 2018 Pioneer Mobile Applications, LLC. All rights reserved.
//

import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
}

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

        guard let request = makeURLRequest(type: type, url: url, parameters: newParams, headers: headers) else {
            completion(false, APIConstants.ErrorType.unknown.error(), nil)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, _ in
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, let data = data else {
                DispatchQueue.main.async {
                    completion(false, APIConstants.ErrorType.unknown.error(), nil)
                }
                return
            }

            let json = try? JSONSerialization.jsonObject(with: data)
            var responseData = json as? [String:Any]
            print("Made request: Status Code = \(statusCode). Data=\(String(describing: responseData))")

            if responseData == nil {
                responseData = ["data": json as? [[String:Any]] ?? []]
            }
            if let responseData = responseData, let error = responseData[APIConstants.Keys.error] as? String {
                DispatchQueue.main.async {
                    completion(false, APIConstants.ErrorType.custom.error(message: error), responseData)
                }
                return
            }

            DispatchQueue.main.async {
                completion(200..<300 ~= statusCode, nil, responseData)
            }
        }.resume()
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

    private func makeURLRequest(type: HTTPMethod, url: String, parameters: [String:Any], headers: [String:String]?) -> URLRequest? {
        guard var components = URLComponents(string: url) else { return nil }

        if type == .get, !parameters.isEmpty {
            components.queryItems = parameters.map { key, value in
                URLQueryItem(name: key, value: String(describing: value))
            }
        }

        guard let requestURL = components.url else { return nil }
        var request = URLRequest(url: requestURL)
        request.httpMethod = type.rawValue
        headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }

        if type != .get, !parameters.isEmpty {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = try? JSONSerialization.data(withJSONObject: parameters)
        }

        return request
    }
}
