import Fluent
import Vapor

func routes(_ app: Application) throws {
    try app.register(collection: AuthController())
    try app.register(collection: GameRoomController())
    try app.register(collection: PlayerController())
}
