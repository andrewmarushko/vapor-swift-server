import Vapor

struct WebsiteController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: indexHandler)
        routes.get("acronyms", ":acronymID", use: acronymHandler)
        routes.get("users", ":userID", use: userHandler)
        routes.get("users", use: allUsersHandler)
        routes.get("categories", use: allCategoriesHandler)
        routes.get("categories", ":categoryID", use: categoryHandler)
        routes.get("acronyms", "create", use: createAcronymHandler)
        routes.post("acronyms", "create", use: createAcronymPostHandler)
        routes.get("acronyms", ":acronymID", "edit", use: editAcronymHandler)
        routes.post("acronyms", ":acronymID", "edit", use: editAcronymPostHandler)
        routes.post("acronyms", ":acronymID", "delete", use: deleteAcronymHandler)
    }

    func indexHandler(_ req: Request) -> EventLoopFuture<View> {
        Acronym.query(on: req.db).all().flatMap { acronyms in
            let context = IndexContext(title: "Home page", acronyms: acronyms)
            return req.view.render("index", context)
        }
    }

    func acronymHandler(_ req: Request) -> EventLoopFuture<View> {
        Acronym.find(req.parameters.get("acronymID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { acronym in
            let userFuture = acronym.$user.get(on: req.db)
            let categoriesFuture = acronym.$categories.query(on: req.db).all()
            return userFuture.and(categoriesFuture).flatMap { user, categories in
                let context = AcronymContext(
                    title: acronym.short,
                    acronym: acronym,
                    user: user,
                    categories: categories)
                return req.view.render("acronym", context)
            }
        }
    }

    func userHandler(_ req: Request) -> EventLoopFuture<View> {
        User.find(req.parameters.get("userID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { user in
            user.$acronyms.get(on: req.db).flatMap { acronyms in
                let context = UserContext(title: user.name, user: user, acronyms: acronyms)
                return req.view.render("user", context)
            }
        }
    }

    func allUsersHandler(_ req: Request) -> EventLoopFuture<View> {
        User.query(on: req.db).all().flatMap { users in
            let context = AllUsersContext(
                title: "All Users",
                users: users)
            return req.view.render("allUsers", context)
        }
    }

    func allCategoriesHandler(_ req: Request) -> EventLoopFuture<View> {
        Category.query(on: req.db).all().flatMap { categories in
            let context = AllCategoriesContext(categories: categories)
            return req.view.render("allCategories", context)
        }
    }

    func categoryHandler(_ req: Request) -> EventLoopFuture<View> {
        Category.find(req.parameters.get("categoryID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { category in
            category.$acronyms.get(on: req.db).flatMap { acronyms in
                let context = CategoryContext(title: category.name, category: category, acronyms: acronyms)
                return req.view.render("category", context)
            }
        }
    }

    func createAcronymHandler(_ req: Request) -> EventLoopFuture<View> {
        User.query(on: req.db).all().flatMap { users in
            let context = CreateAcronymContext(users: users)
            return req.view.render("createAcronym", context)
        }
    }

    func createAcronymPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let data = try req.content.decode(CreateAcronymFormData.self)
        let acronym = Acronym(short: data.short, long: data.long, userID: data.userID)
        return acronym.save(on: req.db).flatMap {
            guard let id = acronym.id else {
                return req.eventLoop.future(error: Abort(.internalServerError))
            }
            var categorySaves: [EventLoopFuture<Void>] = []
            for category in data.categories ?? [] {
                categorySaves.append(Category.addCategory(category, to: acronym, on: req))
            }
            let redirect = req.redirect(to: "/acronyms/\(id)")
            return categorySaves.flatten(on: req.eventLoop).transform(to: redirect)
        }
    }

    func editAcronymHandler(_ req: Request) -> EventLoopFuture<View> {
        let acronymFuture = Acronym.find(req.parameters.get("acronymID"), on: req.db).unwrap(or: Abort(.notFound))
        let userQuery = User.query(on: req.db).all()
        return acronymFuture.and(userQuery).flatMap { acronym, users in
            acronym.$categories.get(on: req.db).flatMap { categories in
                let context = EditAcronymContext(acronym: acronym, users: users, categories: categories)
                return req.view.render("createAcronym", context)
            }
        }
    }

    func editAcronymPostHandler(_ req: Request) throws -> EventLoopFuture<Response> {
        let updateData = try req.content.decode(CreateAcronymFormData.self)
        return Acronym.find(req.parameters.get("acronymID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { acronym in
            acronym.short = updateData.short
            acronym.long = updateData.long
            acronym.$user.id = updateData.userID
            guard let id = acronym.id else {
                return req.eventLoop.future(error: Abort(.internalServerError))
            }
            return acronym.save(on: req.db).flatMap {
                acronym.$categories.get(on: req.db)
            }.flatMap { existingCategories in
                let existingStringArray = existingCategories.map {
                    $0.name
                }

                let existingSet = Set<String>(existingStringArray)
                let newSet = Set<String>(updateData.categories ?? [])

                let categoriesToAdd = newSet.subtracting(existingSet)
                let categoriesToRemove = existingSet.subtracting(newSet)

                var categoryResults: [EventLoopFuture<Void>] = []
                for newCategory in categoriesToAdd {
                    categoryResults.append(Category.addCategory(newCategory, to: acronym, on: req))
                }

                for categoryNameToRemove in categoriesToRemove {
                    let categoryToRemove = existingCategories.first {
                        $0.name == categoryNameToRemove
                    }
                    if let category = categoryToRemove {
                        categoryResults.append(
                            acronym.$categories.detach(category, on: req.db))
                    }
                }

                let redirect = req.redirect(to: "/acronyms/\(id)")
                return categoryResults.flatten(on: req.eventLoop).transform(to: redirect)
            }
        }
    }

    func deleteAcronymHandler(_ req: Request) -> EventLoopFuture<Response> {
        Acronym.find(req.parameters.get("acronymID"), on: req.db).unwrap(or: Abort(.notFound)).flatMap { acronym in
            acronym.delete(on: req.db).transform(to: req.redirect(to: "/"))
        }
    }
}

struct IndexContext: Encodable {
    let title: String
    let acronyms: [Acronym]
}

struct AcronymContext: Encodable {
    let title: String
    let acronym: Acronym
    let user: User
    let categories: [Category]
}

struct UserContext: Encodable {
    let title: String
    let user: User
    let acronyms: [Acronym]
}

struct AllUsersContext: Encodable {
    let title: String
    let users: [User]
}

struct AllCategoriesContext: Encodable {
    let title = "All Categories"
    let categories: [Category]
}

struct CategoryContext: Encodable {
    let title: String
    let category: Category
    let acronyms: [Acronym]
}

struct CreateAcronymContext: Encodable {
    let title = "Create An Acronym"
    let users: [User]
}

struct EditAcronymContext: Encodable {
    let title = "Edit Acronym"
    let acronym: Acronym
    let users: [User]
    let editing = true
    let categories: [Category]
}

struct CreateAcronymFormData: Content {
    let userID: UUID
    let short: String
    let long: String
    let categories: [String]?
}
