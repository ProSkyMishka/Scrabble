//
//  CreateTile.swift
//
//
//  Created by Михаил Прозорский on 21.11.2024.
//

import Fluent

struct CreateTile: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("tiles")
            .id()
            .field("letter", .string, .required)
            .field("value", .int, .required)
            .field("onBoard", .bool, .required)
            .field("player_id", .uuid, .references("players", "id", onDelete: .cascade))
            .field("room_id", .uuid, .required, .references("gamerooms", "id", onDelete: .cascade))
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("tiles").delete()
    }
}
