//
//  Coordinate.swift
//  
//
//  Created by Михаил Прозорский on 22.11.2024.
//

import Foundation
import Vapor

struct Coordinate: Content, Codable {
    let x: Int
    let y: Int
}

