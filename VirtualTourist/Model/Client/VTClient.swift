//
//  VTClient.swift
//  VirtualTourist
//
//  Created by Anderson Rodrigues on 02/03/2020.
//  Copyright © 2020 Anderson Rodrigues. All rights reserved.
//

import Foundation

class VTClient {

    fileprivate struct Auth {
        static var keyId = "b85250cbc70ea1620c1333e3f2df7320"
        static var format = "json"
        static var noCallback: Int = 1
    }

    enum Endpoints {
        static let base = "https://api.flickr.com/services/rest"
        
        case getPhotosForLocation(String)
        case photoImage(String, String, String, Int)
        
        var stringValue: String {
            switch self {
            case .getPhotosForLocation(let value):
                return Endpoints.base + "?\(value)"
            case .photoImage(let id, let secret, let server, let farm):
                return "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret).jpg"
            }
        }
        
        var url: URL {
            return URL(string: stringValue)!
        }
    }
    
    class func taskForPOSTRequest<RequestType: Encodable, ResponseType: Decodable>(from url: URL, responseType: ResponseType.Type, body: RequestType, completion: @escaping(ResponseType?, Error?) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let body = try JSONEncoder().encode(body)
            request.httpBody = body
        } catch {
            completion(nil, error)
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                do {
                    let errorObject = try decoder.decode(ErrorResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil, errorObject)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
            }
        }
        
        task.resume()
    }
    
    class func taskForGETRequest<ResponseType: Decodable>(from url: URL, responseType: ResponseType.Type, completion: @escaping(ResponseType?, Error?) -> Void) {
        
        let session = URLSession.shared
        let task = session.dataTask(with: url) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                do {
                    let errorObject = try decoder.decode(ErrorResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(nil, errorObject)
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error)
                    }
                }
                
            }
        }
        
        task.resume()
    }
    
    class func getPhotosByLocation(lat: Double, long: Double, page: Int, completion: @escaping([PhotoData], Error?) -> Void) {
        let query = "method=flickr.photos.search&api_key=\(Auth.keyId)&lat=\(lat)&lon=\(long)&format=\(Auth.format)&nojsoncallback=\(Auth.noCallback)&per_page=15&page=\(page)"
        
        taskForGETRequest(from: Endpoints.getPhotosForLocation(query).url, responseType: PhotosSearchResults.self) { (response, error) in
            if let response = response {
                completion(response.photos.photoResult, nil)
            } else {
                completion([], error)
            }
        }
    }
    
    class func downloadPhotoImage(id: String, secret: String, serverId: String, farmId: Int, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: Endpoints.photoImage(id, secret, serverId, farmId).url) { data, response, error in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        task.resume()
    }
    
}
