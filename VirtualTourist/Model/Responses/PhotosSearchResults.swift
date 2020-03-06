//
//  PhotosSearchResults.swift
//  VirtualTourist
//
//  Created by Anderson Rodrigues on 03/03/2020.
//  Copyright © 2020 Anderson Rodrigues. All rights reserved.
//

import UIKit

struct PhotosSearchResults: Codable {
    let photos: SearchResult
    let stat: String
    
    enum CodingKeys: String, CodingKey {
        case photos
        case stat
    }
}

internal struct SearchResult: Codable {
    let page: Int
    let pages: Int
    let perPage: Int
    let total: String
    let photoResult: [PhotoData]
    
    enum CodingKeys: String, CodingKey {
        case page
        case pages
        case perPage = "perpage"
        case total
        case photoResult = "photo"
    }
}

internal struct PhotoData: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let isPublic: Int
    let isFriend: Int
    let isFamily: Int
    
    enum CodingKeys: String, CodingKey {
        case id
        case owner
        case secret
        case server
        case farm
        case title
        case isPublic = "ispublic"
        case isFriend = "isfriend"
        case isFamily = "isfamily"
    }
}
