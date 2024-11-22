//
//  CreateTilesForSpecificRoom.swift
//  
//
//  Created by Михаил Прозорский on 21.11.2024.
//

import Fluent
import Foundation

struct CreateTilesForSpecificRoom: AsyncMigration {
    let roomID: UUID

    init(roomID: UUID) {
        self.roomID = roomID
    }

    func prepare(on database: Database) async throws {
        let tileDefinitions: [(letter: String, value: Int, count: Int)] = [
            ("A", 1, 9),
            ("B", 3, 2),
            ("C", 3, 2),
            ("D", 2, 4),
            ("E", 1, 12),
            ("F", 4, 2),
            ("G", 2, 3),
            ("H", 4, 2),
            ("I", 1, 9),
            ("J", 8, 1),
            ("K", 5, 1),
            ("L", 1, 4),
            ("M", 3, 2),
            ("N", 1, 6),
            ("O", 1, 8),
            ("P", 3, 2),
            ("Q", 10, 1),
            ("R", 1, 6),
            ("S", 1, 4),
            ("T", 1, 6),
            ("U", 1, 4),
            ("V", 4, 2),
            ("W", 4, 2),
            ("X", 8, 1),
            ("Y", 4, 2),
            ("Z", 10, 1),
            ("_", 0, 2)
        ]

        for tileDefinition in tileDefinitions {
            for _ in 0..<tileDefinition.count {
                let tile = Tile(letter: tileDefinition.letter, value: tileDefinition.value, roomID: roomID)
                try await tile.save(on: database)
            }
        }
    }

    func revert(on database: Database) async throws {
        try await database.schema("tiles").delete()
    }
}
