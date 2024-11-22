//
//  WordMoveRequest.swift
//  
//
//  Created by Михаил Прозорский on 22.11.2024.
//

import Foundation
import Vapor

struct WordMoveRequest: Content, Codable {
    let word: String
    let coordinates: [Coordinate]
}
