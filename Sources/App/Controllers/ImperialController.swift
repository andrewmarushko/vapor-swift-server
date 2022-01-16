import ImperialGoogle
import ImperialGitHub
import Vapor
import Fluent
import Foundation

struct ImperialController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        guard let googleCallbackURL =
                Environment.get("GOOGLE_CALLBACK_URL") else {
                    fatalError("Google callback URL not set")
                }
        try routes.oAuth(
            from: Google.self,
            authenticate: "login-google",
            callback: googleCallbackURL,
            scope: ["profile", "email"],
            completion: processGoogleLogin)

        guard let githubCallbackURL = Environment.get("GITHUB_CALLBACK_URL") else {
            fatalError("Github callback URL not set")
        }

        try routes.oAuth(from: GitHub.self, authenticate: "login-github", callback: githubCallbackURL, completion: processGoogleLogin)

        routes.get("iOS", "login-google", use: iOSGoogleLogin)
    }

    func processGoogleLogin(request: Request, token: String) throws -> EventLoopFuture<ResponseEncodable> {
        try Google.getUser(on: request).flatMap { userInfo in
            User.query(on: request.db).filter(\.$username == userInfo.email).first().flatMap { foundUser in
                guard let existingUser = foundUser else {
                    let user = User(name: userInfo.name, username: userInfo.email, password: UUID().uuidString)
                    return user.save(on: request.db).flatMap {
                        request.session.authenticate(user)
                        return generateRedirect(on: request, for: user)
                    }
                }
                request.session.authenticate(existingUser)
                return generateRedirect(on: request, for: existingUser)
            }
        }
    }

    func processGithubLogin(request: Request, token: String) throws -> EventLoopFuture<ResponseEncodable> {
       return try GitHub
            .getUser(on: request)
            .flatMap { userInfo in
                return User
                    .query(on: request.db)
                    .filter(\.$username == userInfo.login)
                    .first()
                    .flatMap { foundUser in
                        guard let existingUser = foundUser else {
                            let user = User(
                                name: userInfo.name, username: userInfo.login, password: UUID().uuidString
                            )

                            return user.save(on: request.db)
                                .flatMap {
                                    request.session.authenticate(user)
                                    return generateRedirect(on: request, for: user)
                                }
                        }

                        request.session.authenticate(existingUser)
                        return generateRedirect(on: request, for: existingUser)
                    }
            }
    }

    func iOSGoogleLogin(_ req: Request) -> Response {
        req.session.data["oauth_login"] = "iOS"
        return req.redirect(to: "/login-google")
    }

    func generateRedirect(on req: Request, for user: User) -> EventLoopFuture<ResponseEncodable> {
        let redirectURL: EventLoopFuture<String>
        if req.session.data["oauth_login"] == "iOS" {
            do {
                let token = try Token.generate(for: user)
                redirectURL = token.save(on: req.db).map {
                    "tilapp://auth?token=\(token.value)"
                }
            } catch {
                return req.eventLoop.future(error: error)
            }
        } else {
            redirectURL = req.eventLoop.future("/")
        }
        req.session.data["oauth_login"] = nil
        return redirectURL.map { url in
            req.redirect(to: url)
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
        return request.client.get(googleAPIURL, headers: headers).flatMapThrowing { response in
            guard response.status == .ok else {
                if response.status == .unauthorized {
                    throw Abort.redirect(to: "/login-google")
                } else {
                    throw Abort(.internalServerError)
                }
            }
            return try response.content.decode(GoogleUserInfo.self)
        }
    }
}


struct GithubUserInfo: Content {
    let name: String
    let login: String
}

extension GitHub {
    static func getUser(on request: Request) throws -> EventLoopFuture<GithubUserInfo> {

        var headers = HTTPHeaders()
        try headers.add(name: .authorization, value: "token \(request.accessToken())")
        headers.add(name: .userAgent, value: "vapor")

        let githubUserAPIURL: URI = "https://api.github.com/user"

        return request.client.get(githubUserAPIURL, headers: headers).flatMapThrowing { response in
            guard response.status == .ok else {
                if response.status == .unauthorized {
                    throw Abort.redirect(to: "/login-github")
                } else {
                    throw Abort(.internalServerError)
                }
            }

            return try response.content.decode(GithubUserInfo.self)
        }
    }
}
