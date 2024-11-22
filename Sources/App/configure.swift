import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import JWT

// configures your application
public func configure(_ app: Application) async throws {
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    app.jwt.signers.use(.hs256(key: "secret"))
    
    app.databases.use(DatabaseConfigurationFactory.postgres(configuration: .init(
        hostname: Environment.get("DATABASE_HOST") ?? "0.0.0.0",
        port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? SQLPostgresConfiguration.ianaPortNumber,
        username: Environment.get("DATABASE_USERNAME") ?? "teamWork_username",
        password: Environment.get("DATABASE_PASSWORD") ?? "teamWork_password",
        database: Environment.get("DATABASE_NAME") ?? "teamWork_database",
        tls: .prefer(try .init(configuration: .clientDefault)))
    ), as: .psql)

    app.migrations.add(CreateUser())
    app.migrations.add(CreateGameRoom())
    app.migrations.add(CreatePlayer())
    app.migrations.add(CreateTile())

    try await app.autoMigrate().get()
    // register routes
    try routes(app)
}
