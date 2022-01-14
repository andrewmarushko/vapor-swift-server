//
//  File.swift
//  
//
//  Created by Andrew Marushko on 13.01.2022.
//

import Fluent
import Vapor
import Foundation

final class User: Model, Content {
    static let schema = "users"


    @ID
    var id: UUID?

    @Field(key: "name")
    var name: String

    @Field(key: "username")
    var username: String

    init() {}

    init(id: UUID? = nil, name: String, username: String) {
        self.name = name
        self.username = username
    }
}
