//
//  CreatePlayer.swift
//  
//
//  Created by Михаил Прозорский on 21.11.2024.
//

import Fluent

struct CreatePlayer: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("players")
            .id()
            .field("user_id", .uuid, .required, .references("users", "id", onDelete: .cascade))
            .field("room_id", .uuid, .required, .references("gamerooms", "id", onDelete: .cascade))
            .field("score", .int, .required)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("players").delete()
    }
}
