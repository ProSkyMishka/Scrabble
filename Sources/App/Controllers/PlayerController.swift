//
//  PlayerController.swift
//
//
//  Created by Михаил Прозорский on 22.11.2024.
//

import Vapor
import Fluent

struct PlayerController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let players = routes.grouped("players")
        
        let protected = players.grouped(JWTMiddleware())
        protected.get(":id", "list", use: listTile)
    }
    
    @Sendable
    func listTile(req: Request) async throws -> [Tile] {
        guard let playerID = req.parameters.get("id", as: UUID.self) else {
            throw Abort(.badRequest)
        }
        
        let playerTiles = try await Tile.query(on: req.db)
            .filter(\.$player.$id == playerID)
            .filter(\.$onBoard == false)
            .all()
        
        return playerTiles
    }
    
    func updatePlayerScore(req: Request, playerID: UUID, score: Int) async throws {
        guard let player = try await Player.query(on: req.db)
            .filter(\.$id == playerID)
            .first() else {
            throw Abort(.notFound, reason: "Player not found in this room.")
        }
        
        player.score += score
        try await player.save(on: req.db)
    }
    
    func validateWord(req: Request, board: [String], _ word: WordMoveRequest, playerID: UUID, roomID: UUID) async throws -> (Bool, [String]) {
        let playerTiles = try await Tile.query(on: req.db)
            .filter(\.$player.$id == playerID)
            .filter(\.$onBoard == false)
            .all()

        var availableLetters = playerTiles.map { $0.letter }
        var availableValue = playerTiles.map { $0.value }
        
        var boardCopy = GameRoom().toArr(board: board)
        var score = 0
        var i = 0
        for letter in word.word.uppercased() {
            if let index = availableLetters.firstIndex(of: String(letter)) {
                availableLetters.remove(at: index)
                let c = word.coordinates[i]
                score += availableValue[index] * (Int(boardCopy[c.y][c.x]) ?? 1)
                boardCopy[c.y][c.x] = String(letter)
                availableValue.remove(at: index)
                i += 1
            } else {
                return (false, [])
            }
        }
        let dictionary = ["AAA", "DOG", "BIRD", "POTATO", "TOMATO"]
        if dictionary.contains(word.word.uppercased()) {
            try await updatePlayerScore(req: req, playerID: playerID, score: score)
            return (true, GameRoom().toString(board: boardCopy))
        }
        return (false, [])
    }
}
