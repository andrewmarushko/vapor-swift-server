import Fluent

struct CreateCategory: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
      database.schema(Category.v20210113.schemaName)
      .id()
      .field(Category.v20210113.name, .string, .required)
      .create()
  }
  
  func revert(on database: Database) -> EventLoopFuture<Void> {
      database.schema(Category.v20210113.schemaName).delete()
  }
}


extension Category {
    enum v20210113 {
        static let schemaName = "categories"
        static let name = FieldKey(stringLiteral: "name")
        static let id = FieldKey(stringLiteral: "id")
    }
}
