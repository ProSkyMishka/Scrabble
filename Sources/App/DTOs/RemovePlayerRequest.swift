//
//  RemovePlayerRequest.swift
//  
//
//  Created by Михаил Прозорский on 22.11.2024.
//

import Foundation
import Vapor

struct RemovePlayerRequest: Content {
    let userID: UUID
}

struct RoomRequest: Content {
    let code: String
}
