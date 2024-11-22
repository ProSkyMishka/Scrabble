//
//  AuthController.swift
//
//
//  Created by Михаил Прозорский on 21.11.2024.
//

import Vapor
import Fluent
import JWT

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.post("register", use: register)
        auth.post("login", use: login)

        let protected = auth.grouped(JWTMiddleware())
        protected.get("me", use: getCurrentUser)
    }

    @Sendable
    func register(req: Request) async throws -> HTTPStatus {
        let input = try req.content.decode(RegisterRequest.self)
        
        guard try await User.query(on: req.db)
                .filter(\.$name == input.name)
                .first() == nil else {
            throw Abort(.badRequest, reason: "Username is already taken")
        }

        let hashedPassword = try Bcrypt.hash(input.password)
        let newUser = User(name: input.name, password: hashedPassword)
        try await newUser.save(on: req.db)
        return .created
    }

    @Sendable
    func login(req: Request) async throws -> TokenResponse {
        let input = try req.content.decode(LoginRequest.self)
        
        guard let user = try await User
            .query(on: req.db)
            .filter(\.$name == input.name)
            .first()
        else { throw Abort(.notFound) }

        guard try Bcrypt.verify(input.password, created: user.password) else {
            throw Abort(.unauthorized, reason: "Invalid username or password")
        }

        let payload = UserPayload(userID: try user.requireID())
        let token = try req.jwt.sign(payload)
        return TokenResponse(token: token)
    }

    @Sendable
    func getCurrentUser(req: Request) async throws -> User.Public {
        let payload = try req.auth.require(UserPayload.self)
        guard let user = try await User.find(payload.userID, on: req.db) else {
            throw Abort(.notFound)
        }
        return user.convertToPublic()
    }
}

struct RegisterRequest: Content {
    let name: String
    let password: String
}

struct LoginRequest: Content {
    let name: String
    let password: String
}

struct TokenResponse: Content {
    let token: String
}

struct UserPayload: JWTPayload, Authenticatable {
    var userID: UUID
    var exp: ExpirationClaim

    init(userID: UUID) {
        self.userID = userID
        self.exp = .init(value: .distantFuture)
    }

    func verify(using signer: JWTSigner) throws {
        try exp.verifyNotExpired()
    }
}

struct JWTMiddleware: AsyncMiddleware {
    func respond(to req: Request, chainingTo next: AsyncResponder) async throws -> Response {
        let token = req.headers.bearerAuthorization?.token
        guard let token = token else {
            throw Abort(.unauthorized, reason: "Missing or invalid token")
        }

        req.auth.login(try req.jwt.verify(token, as: UserPayload.self))
        return try await next.respond(to: req)
    }
}

