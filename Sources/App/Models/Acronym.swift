import Fluent
import Vapor
import Foundation

final class Acronym: Model {
    static let schema = "acronyms"

    @ID
    var id: UUID?

    @Field(key: "short")
    var short: String

    @Field(key: "long")
    var long: String

    init() {}

    init(id: UUID?, short: String, long: String) {
        self.id = id
        self.short = short
        self.long = long
    }
}

extension Acronym: Content {}
