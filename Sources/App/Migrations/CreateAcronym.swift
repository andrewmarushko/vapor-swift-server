import Fluent

struct CreateAcronym: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
      database.schema(Acronym.v20210114.schemaName)
      .id()
      .field(Acronym.v20210114.short, .string, .required)
      .field(Acronym.v20210114.long, .string, .required)
      .field(Acronym.v20210114.userID, .uuid, .required, .references(User.v20210113.schemaName, User.v20210113.id))
      .field("createdAt", .datetime)
      .field("updatedAt", .datetime)
      .create()
  }
  
  func revert(on database: Database) -> EventLoopFuture<Void> {
      database.schema(Acronym.v20210114.schemaName).delete()
  }
}

extension Acronym {
    enum v20210114 {
        static let schemaName = "acronyms"

        static let id = FieldKey(stringLiteral: "id")
        static let short = FieldKey(stringLiteral: "short")
        static let long = FieldKey(stringLiteral: "long")
        static let userID = FieldKey(stringLiteral: "userID")
    }
}
