import Vapor
import Leaf


struct WebsiteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: indexHandler)
        routes.get("acronyms", ":acronymID", use: acronymHandler)
    }

    func indexHandler(_ req: Request)
    -> EventLoopFuture<View> {
        Acronym.query(on: req.db).all().flatMap { acronyms in
            let acronymsData = acronyms.isEmpty ? nil : acronyms
            let context = IndexContext(
                title: "Home page",
                acronyms: acronymsData)
            return req.view.render("index", context)
        }
    }

    func acronymHandler(_ req: Request) -> EventLoopFuture<View> {
        Acronym.find(req.parameters.get("acronymID"), on: req.db)
            .unwrap(or: Abort(.notFound))
            .flatMap { acronym in
                acronym.$user.get(on: req.db).flatMap { user in
                    let context = AcronymContext(title: acronym.short, acronym: acronym, user: user)
                    return req.view.render("acronym", context)
                }
            }
    }
}


struct IndexContext: Encodable {
    let title: String
    let acronyms: [Acronym]?
}

struct AcronymContext: Encodable {
    let title: String
    let acronym: Acronym
    let user: User
}
