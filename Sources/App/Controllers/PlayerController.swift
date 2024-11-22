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
        var tilesToDelete: [Tile] = []
        
        let playerTiles = try await Tile.query(on: req.db)
            .filter(\.$player.$id == playerID)
            .filter(\.$onBoard == false)
            .all()
        let tiles = try await Tile.query(on: req.db)
            .filter(\.$room.$id == roomID)
            .filter(\.$onBoard == true)
            .all()
        let letters = tiles.map { $0.letter }
        let values = tiles.map { $0.value }
        var availableLetters = playerTiles.map { $0.letter }
        var availableValue = playerTiles.map { $0.value }
        
        var boardCopy = GameRoom().toArr(board: board)
        var score = 0
        var i = 0
        var count = 0
        for letter in word.word.uppercased() {
            let c = word.coordinates[i]
            if boardCopy[c.y][c.x] == String(letter)  {
                let index = letters.firstIndex(of: String(letter))
                score += values[index!]
                i += 1
                continue
            }
            if let index = availableLetters.firstIndex(of: String(letter)) {
                availableLetters.remove(at: index)
                score += availableValue[index] * (Int(boardCopy[c.y][c.x]) ?? 1)
                boardCopy[c.y][c.x] = String(letter)
                availableValue.remove(at: index)
                tilesToDelete.append(playerTiles[index])
                i += 1
                count += 1
            } else {
                if let index = availableLetters.firstIndex(of: "_") {
                    availableLetters.remove(at: index)
                    let indexTwo = letters.firstIndex(of: String(letter))
                    score += values[indexTwo!]
                    boardCopy[c.y][c.x] = String(letter)
                    availableValue.remove(at: index)
                    tilesToDelete.append(playerTiles[index])
                    i += 1
                    count += 1
                    continue
                }
                return (false, [])
            }
        }
        let dictionary = ["VORS", "RIKE", "TIE", "CAT", "DOG", "BIRD", "POTATO", "TOMATO"]
        if dictionary.contains(word.word.uppercased()) {
            try await updatePlayerScore(req: req, playerID: playerID, score: score)
            let tiles = try await Tile.query(on: req.db)
                .filter(\.$room.$id == roomID)
                .filter(\.$player.$id == nil)
                .filter(\.$onBoard == false)
                .sort(.custom("RANDOM()"))
                .limit(count)
                .all()
            
            for tile in tiles {
                tile.$player.id = playerID
                try await tile.save(on: req.db)
            }
            
            for tile in tilesToDelete {
                tile.onBoard = true
                try await tile.save(on: req.db)
            }
            return (true, GameRoom().toString(board: boardCopy))
        }
        return (false, [])
    }
}
