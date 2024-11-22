//
//  GameRoomController.swift
//
//
//  Created by Михаил Прозорский on 21.11.2024.
//

import Fluent
import Vapor
import WebKit

struct GameRoomController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let gameRooms = routes.grouped("gamerooms")
        
        let protected = gameRooms.grouped(JWTMiddleware())
        protected.post("create", use: create)
        protected.get("list", use: list)
        protected.get(":id", use: get)
        protected.post(":id", "join", use: join)
        protected.delete(":id", "remove", use: removePlayer)
        protected.put(":id", "toggle", use: toggleRound)
        protected.get(":id", "count", use: countTiles)
        protected.get(":id", "leaders", use: getLeaderboard)
        protected.delete(":id", use: delete)
        protected.put(":id", "move", use: turn)
    }

    @Sendable
    func create(req: Request) async throws -> GameRoom {
        let payload = try req.auth.require(UserPayload.self)
        
        let createRoomRequest = try req.content.decode(RoomRequest.self)
        
        var board = Array(repeating: Array(repeating: "1" as String, count: 15), count: 15)
        board[7][7] = "5"
        var boardStr: [String] = []
        for i in board {
            var str = ""
            for j in 0...13 {
                str += "\(i[j]),"
            }
            boardStr.append(str + i[14])
        }
        let gameRoom = GameRoom(
            adminID: payload.userID,
            board: GameRoom().toString(board: board),
            code: createRoomRequest.code
        )
        try await gameRoom.save(on: req.db)
        let migration = CreateTilesForSpecificRoom(roomID: try gameRoom.requireID())
        try await migration.prepare(on: req.db)
        return gameRoom
    }

    @Sendable
    func list(req: Request) async throws -> [GameRoom] {
        try await GameRoom.query(on: req.db)
            .filter(\.$isActive == false)
            .all()
    }

    @Sendable
    func get(req: Request) async throws -> GameRoom {
        guard let room = try await GameRoom.find(req.parameters.get("id"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        if room.isActive {
            throw Abort(.forbidden, reason: "The game is already started.")
        }
        
        return room
    }

    @Sendable
    func join(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        
        guard let roomID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        let joinRequest = try req.content.decode(RoomRequest.self)
        guard let room = try await GameRoom.find(roomID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        if !room.code.isEmpty && room.code != joinRequest.code || room.isActive {
            throw Abort(.forbidden, reason: "Invalid room code.")
        }
        
        let existingPlayer = try await Player.query(on: req.db)
            .filter(\.$room.$id == room.requireID())
            .filter(\.$user.$id == payload.userID)
            .first()
        
        guard existingPlayer == nil else {
            throw Abort(.conflict, reason: "User is already part of this room.")
        }
        
        let player = Player(userID: payload.userID, score: 0, roomID: try room.requireID())
        try await player.save(on: req.db)
        
        let tiles = try await Tile.query(on: req.db)
            .filter(\.$room.$id == room.requireID())
            .filter(\.$player.$id == nil)
            .filter(\.$onBoard == false)
            .limit(7)
            .all()
        
        for tile in tiles {
            tile.$player.id = try player.requireID()
            try await tile.save(on: req.db)
        }
        
        return .ok
    }
    
    @Sendable
    func removePlayer(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        guard let roomID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Room ID is required.")
        }
        
        guard let room = try await GameRoom.find(roomID, on: req.db),
              room.adminID == payload.userID else {
            throw Abort(.forbidden, reason: "Only the admin can remove players.")
        }
        
        let removeRequest = try req.content.decode(RemovePlayerRequest.self)
        
        guard let player = try await Player.query(on: req.db)
            .filter(\.$id == removeRequest.userID)
            .first() else {
            throw Abort(.notFound, reason: "Player not found in this room.")
        }
        
        try await player.delete(on: req.db)
        return .ok
    }
    
    @Sendable
    func toggleRound(req: Request) async throws -> HTTPStatus {
        let payload = try req.auth.require(UserPayload.self)
        guard let roomID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Room ID is required.")
        }
        
        guard let room = try await GameRoom.find(roomID, on: req.db),
              room.adminID == payload.userID else {
            throw Abort(.forbidden, reason: "Only the admin can start the round.")
        }
        
        room.isActive.toggle()
        try await room.save(on: req.db)
        return .ok
    }


    @Sendable
    func delete(req: Request) async throws -> HTTPStatus {
        guard let roomID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid room ID.")
        }
        
        let payload = try req.auth.require(UserPayload.self)

        guard let room = try await GameRoom.find(roomID, on: req.db) else {
            throw Abort(.notFound, reason: "Room not found.")
        }

        guard room.adminID == payload.userID else {
            throw Abort(.forbidden, reason: "You are not the admin of this room.")
        }

        try await room.delete(on: req.db)
        return .ok
    }
    
    @Sendable
    func countTiles(req: Request) async throws -> Int {
        guard let roomID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid room ID.")
        }
        
        let tiles = try await Tile.query(on: req.db)
            .filter(\.$room.$id == roomID)
            .filter(\.$player.$id == nil)
            .filter(\.$onBoard == false)
            .all()
        
        return tiles.count
    }
    
    @Sendable
    func getLeaderboard(req: Request) async throws -> [Player] {
        try await Player.query(on: req.db)
            .filter(\.$room.$id == req.parameters.get("id", as: UUID.self)!)
            .sort(\.$score, .descending)
            .all()
    }
    
    @Sendable
    func turn(req: Request) async throws -> GameRoom {
        let payload = try req.auth.require(UserPayload.self)
        guard let roomID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Room ID is required.")
        }
        
        guard let room = try await GameRoom.query(on: req.db)
                .with(\.$players)
                .filter(\.$id == roomID)
                .first() else {
            throw Abort(.notFound, reason: "Room not found.")
        }
        
        guard room.players[room.turn].$user.id == payload.userID else {
            throw Abort(.forbidden, reason: "It's not your turn.")
        }
        
        guard let player = try await Player.query(on: req.db)
            .filter(\.$room.$id == roomID)
            .filter(\.$user.$id == payload.userID)
            .first()
        else {
            throw Abort(.notFound, reason: "Player not found.")
        }
        
        let moveRequest = try req.content.decode(WordMoveRequest.self)
        
        var result = try await PlayerController().validateWord(req: req, board: room.board, moveRequest, playerID: player.id!, roomID: roomID)
        if result.0 {
            room.board = result.1
            if (room.turn + 1 >= room.players.count) {
                room.turn = 0
            } else {
                room.turn += 1
            }
            print(result.1)
            try await room.save(on: req.db)
        }
        
        return room
    }
}








