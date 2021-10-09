//
//  Constants.swift
//  VirtualTourist
//
//  Created by Anderson Rodrigues on 17/03/2020.
//  Copyright © 2020 Anderson Rodrigues. All rights reserved.
//

import Foundation

private let apiKey = "b85250cbc70ea1620c1333e3f2df7320"

/// Enum Method to define types that can be used to make a request
enum Method: String {
    case get = "GET"
    case post = "POST"
}

/// Enum Endpoint defines all URL requests that the app can use to send
enum Endpoint {
    static private let base = "https://api.flickr.com/services/rest/"
    
    case getPhotosForLocation(String)
    case photoImage(String, String, String, Int)
    
    var stringValue: String {
        switch self {
        case .getPhotosForLocation(let value):
            return Endpoint.base + "?method=flickr.photos.search&api_key=\(apiKey)&format=json&nojsoncallback=1&per_page=15&\(value)"
        case .photoImage(let id, let secret, let server, let farm):
            return "https://farm\(farm).staticflickr.com/\(server)/\(id)_\(secret).jpg"
        }
    }
    
    var url: URL {
        return URL(string: stringValue)!
    }
}
