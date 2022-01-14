import Fluent
import Vapor

func routes(_ app: Application) throws {

    app.get("api", "acronyms", "search") { req -> EventLoopFuture<[Acronym]> in
        guard let searchTerm = req.query[String.self, at: "term"] else {
            throw Abort(.badRequest)
        }

        return Acronym.query(on: req.db).group(.or) { or in
            or.filter(\.$short == searchTerm)
            or.filter(\.$long == searchTerm)
        }.all()
    }

    let acronymsController = AcronymsController()
    let usersController = UsersController()

    try app.register(collection: usersController)
    try app.register(collection: acronymsController)
}

 
struct InfoData: Content {
    let name: String
}

struct InfoResponce: Content {
    let request: InfoData
}
