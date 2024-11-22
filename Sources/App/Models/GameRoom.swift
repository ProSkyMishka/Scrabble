//
//  GameRoom.swift
//  
//
//  Created by Михаил Прозорский on 21.11.2024.
//

import Fluent
import Vapor

final class GameRoom: Model, Content {
    static let schema = "gamerooms"
    var connections = [String: WebSocket]()
    
    @ID var id: UUID?
    
    @Field(key: "adminID") var adminID: UUID
    @Field(key: "code") var code: String
    @Field(key: "turn") var turn: Int
    @Field(key: "board") var board: [String]
    @Field(key: "isActive") var isActive: Bool
    
    @Children(for: \.$room) var players: [Player]
    
    @Children(for: \.$room) var tiles: [Tile]
    
    init() {}
    
    init(id: UUID? = nil, adminID: UUID, board: [String], code: String, isActive: Bool = false) {
        self.id = id
        self.adminID = adminID
        self.board = board
        self.code = code
        self.isActive = isActive
        self.turn = 0
    }
}

extension GameRoom {
    func send(message: ByteBuffer) {
        for (_, websocket) in connections {
            websocket.send(message)
        }
    }
    
    func toString(board: [[String]]) -> [String] {
        var boardStr: [String] = []
        for i in board {
            var str = ""
            for j in 0...13 {
                str += "\(i[j]),"
            }
            boardStr.append(str + i[14])
        }
        
        return boardStr
    }
    
    func toArr(board: [String]) -> [[String]] {
        var boardArr: [[String]] = []
        for i in board {
            var arr: [String] = []
            var arrCopy = i.split(separator: ",")
            for j in arrCopy {
                arr.append(String(j))
            }
            boardArr.append(arr)
        }
        
        return boardArr
    }
}
