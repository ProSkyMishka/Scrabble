//
//  CreateGameRoom.swift
//
//
//  Created by Михаил Прозорский on 21.11.2024.
//

import Fluent

struct CreateGameRoom: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("gamerooms")
            .id()
            .field("adminID", .uuid, .required)
            .field("code", .string, .required)
            .field("board", .array(of: .string), .required)
            .field("isActive", .bool, .required)
            .field("turn", .int)
            .create()
    }

    func revert(on database: Database) async throws {
        try await database.schema("gamerooms").delete()
    }
}
