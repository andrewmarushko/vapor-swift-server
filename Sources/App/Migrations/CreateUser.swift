import Fluent

struct CreateUser: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
      database.schema(User.v20210113.schemaName)
      .id()
      .field(User.v20210113.name, .string, .required)
      .field(User.v20210113.username, .string, .required)
      .field(User.v20210113.email, .string, .required).unique(on: User.v20210113.username)
      .field(User.v20210113.password, .string, .required)
      .field("deleted_at", .datetime)
      .field("profilePicture", .string)
      .unique(on: "username")
      .create()
  }
  
  func revert(on database: Database) -> EventLoopFuture<Void> {
      database.schema(User.v20210113.schemaName).delete()
  }
}

extension User {
    enum v20210113 {
        static let schemaName = "users"
        static let id = FieldKey(stringLiteral: "id")
        static let name = FieldKey(stringLiteral: "name")
        static let username = FieldKey(stringLiteral: "username")
        static let password = FieldKey(stringLiteral: "password")
        static let email = FieldKey(stringLiteral: "email")
    }

    enum v20210114 {
        static let twitterURL = FieldKey(stringLiteral: "twitterURL")
    }
}
