//
//  ErrorResponse.swift
//  VirtualTourist
//
//  Created by Anderson Rodrigues on 02/03/2020.
//  Copyright © 2020 Anderson Rodrigues. All rights reserved.
//

import Foundation

struct ErrorResponse: Codable {
    let status: String
    let code: Int
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case status = "stat"
        case code
        case message
    }
}

extension ErrorResponse: LocalizedError {
    var errorDescription: String? {
        return message
    }
}
