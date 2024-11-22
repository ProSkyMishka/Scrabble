//
//  User.swift
//
//
//  Created by Михаил Прозорский on 21.11.2024.
//

import Fluent
import Vapor

final class User: Model, Content {
    static var schema: String = "users"
    
    @ID var id: UUID?
    @Field(key: "name") var name: String
    @Field(key: "password") var password: String
    
    init() { }
    
    init(id: UUID? = nil, name: String, password: String) {
        self.id = id
        self.name = name
        self.password = password
    }
    
    final class Public: Content {
        var id: UUID?
        var name: String
        
        init(id: UUID? = nil, name: String) {
            self.id = id
            self.name = name
        }
    }
}

extension User {
    func convertToPublic() -> User.Public {
        let pub = Public(id: self.id, name: self.name)
        return pub
    }
}
