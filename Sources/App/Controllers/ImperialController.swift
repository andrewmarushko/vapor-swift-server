import ImperialGoogle
import Vapor
import Fluent

struct ImperialController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        guard let googleCallbackURL = Environment.get("GOOGLE_CALLBACK_URL") else {
            fatalError("Google callback URL not set")
        }

        try routes.oAuth(
            from: Google.self,
            authenticate: "login-google",
            callback: googleCallbackURL,
            scope: ["profile", "email"],
            completion: processGoogleLogin)
    }

    func processGoogleLogin(request: Request, token: String)
    throws -> EventLoopFuture<ResponseEncodable> {
        try Google.getUser(on: request)
            .flatMap { userInfo in
                User.query(on: request.db)
                    .filter(\.$username == userInfo.email)
                    .first()
                    .flatMap { foundUser in
                        guard let existingUser = foundUser else {
                            let user = User(
                                name: userInfo.name,
                                username: userInfo.email,
                                password: UUID().uuidString,
                                email: userInfo.email)

                            return user.save(on: request.db)
                                .map {
                                    request.session.authenticate(user)
                                    return request.redirect(to: "/")
                                }
                        }

                        request.session.authenticate(existingUser)
                        return request.eventLoop.future(request.redirect(to: "/"))
                    }
            }
    }
}


struct GoogleUserInfo: Content {
    let email: String
    let name: String
}

extension Google {
    static func getUser(on request: Request) throws -> EventLoopFuture<GoogleUserInfo> {
        var headers = HTTPHeaders()
        headers.bearerAuthorization = try BearerAuthorization(token: request.accessToken())

        let googleAPIURL: URI = "https://www.googleapis.com/oauth2/v1/userinfo?alt=json"

        return request.client.get(googleAPIURL, headers: headers)
            .flatMapThrowing { resonse in
                guard resonse.status == .ok else {
                    if resonse.status == .unauthorized {
                        throw Abort.redirect(to: "/login-google")
                    } else {
                        throw Abort(.internalServerError)
                    }
                }

                return try resonse.content.decode(GoogleUserInfo.self)
            }
    }
}
