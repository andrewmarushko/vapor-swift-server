import Fluent
import Vapor

struct CreateAdminUser: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
    let passwordHash: String
    do {
      passwordHash = try Bcrypt.hash("password")
    } catch {
      return database.eventLoop.future(error: error)
    }
    let user = User(name: "Admin", username: "admin", password: passwordHash)
    return user.save(on: database)
  }

  func revert(on database: Database) -> EventLoopFuture<Void> {
    User.query(on: database).filter(\.$username == "admin").delete()
  }
}
