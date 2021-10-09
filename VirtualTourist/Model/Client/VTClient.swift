//
//  VTClient.swift
//  VirtualTourist
//
//  Created by Anderson Rodrigues on 02/03/2020.
//  Copyright © 2020 Anderson Rodrigues. All rights reserved.
//

import Foundation

typealias Response<ResponseType: Decodable> = Result<ResponseType, Error>

class VTClient {

    private class func taskForPOSTRequest<RequestType: Encodable, ResponseType: Decodable>(from url: URL, responseType: ResponseType.Type, body: RequestType, completion: @escaping(Response<ResponseType>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            let body = try JSONEncoder().encode(body)
            request.httpBody = body
        } catch {
            DispatchQueue.main.async {
                completion(.failure(error))
            }
            
        }
        
        let session = URLSession.shared
        let task = session.dataTask(with: request) { (data, response, error) in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure())
                }
                return
            }
            
            let decoder = JSONDecoder()
            do {
                let responseObject = try decoder.decode(ResponseType.self, from: data)
                DispatchQueue.main.async {
                    completion(.success(responseObject))
                }
            } catch {
                do {
                    let errorObject = try decoder.decode(ErrorResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(.failure(errorObject))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
            }
        }
        
        task.resume()
    }
    
    private class func taskForGETRequest<ResponseType: Decodable>(from url: URL, responseType: ResponseType.Type, completion: @escaping(Response<ResponseType>) -> Void) {
        
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
                    completion(.success(responseObject))
                }
            } catch {
                do {
                    let errorObject = try decoder.decode(ErrorResponse.self, from: data)
                    DispatchQueue.main.async {
                        completion(.failure(errorObject))
                    }
                } catch {
                    DispatchQueue.main.async {
                        completion(.failure(error))
                    }
                }
                
            }
        }
        
        task.resume()
    }
    
    class func getPhotosByLocation(lat: Double, long: Double, page: Int, completion: @escaping([PhotoData], Error?) -> Void) {
        let query = "lat=\(lat)&lon=\(long)&page=\(page)"
        
        taskForGETRequest(from: Endpoint.getPhotosForLocation(query).url, responseType: PhotosSearchResults.self) { response in
            switch response {
                case .success(let value):
                    return completion(value.photos.photoResult, nil)
                case .failure(let error):
                    return completion([], error)
            }
        }
    }
    
    class func downloadPhotoImage(id: String, secret: String, serverId: String, farmId: Int, completion: @escaping (Data?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: Endpoint.photoImage(id, secret, serverId, farmId).url) { data, response, error in
            DispatchQueue.main.async {
                completion(data, error)
            }
        }
        task.resume()
    }
    
}
