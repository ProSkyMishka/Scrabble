//
//  Tile.swift
//
//
//  Created by Михаил Прозорский on 21.11.2024.
//

import Fluent
import Vapor

final class Tile: Model, Content {
    static let schema = "tiles"
    
    @ID var id: UUID?
    
    @Field(key: "letter") var letter: String
    @Field(key: "value") var value: Int
    @Field(key: "onBoard") var onBoard: Bool
    
    @Parent(key: "room_id") var room: GameRoom
    
    @OptionalParent(key: "player_id") var player: Player?
    
    init() {}
    
    init(id: UUID? = nil, letter: String, value: Int, roomID: UUID, playerID: UUID? = nil, onBoard: Bool = false) {
        self.id = id
        self.letter = letter
        self.value = value
        self.$room.id = roomID
        self.$player.id = playerID
        self.onBoard = onBoard
    }
}

