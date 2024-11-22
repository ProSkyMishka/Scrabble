//
//  Player.swift
//  
//
//  Created by Михаил Прозорский on 21.11.2024.
//

import Fluent
import Vapor

final class Player: Model, Content {
    static let schema = "players"
    
    @ID var id: UUID?
    
    @Parent(key: "user_id") var user: User
    
    @Field(key: "score") var score: Int
    
    @Parent(key: "room_id") var room: GameRoom
    
    @Children(for: \.$player) var handOn: [Tile]
    
    init() {}
    
    init(id: UUID? = nil, userID: UUID, score: Int, roomID: UUID) {
        self.id = id
        self.$user.id = userID
        self.score = score
        self.$room.id = roomID
    }
}

