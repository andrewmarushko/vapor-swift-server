import Fluent

struct CreateAcronymCategoryPivot: Migration {
  func prepare(on database: Database) -> EventLoopFuture<Void> {
      database.schema(AcronymCategoryPivot.v20210113.schemaName)
      .id()
      .field(AcronymCategoryPivot.v20210113.acronymID, .uuid, .required, .references(Acronym.v20210114.schemaName, Acronym.v20210114.id, onDelete: .cascade))
      .field("categoryID", .uuid, .required, .references("categories", "id", onDelete: .cascade))
      .create()
  }
  
  func revert(on database: Database) -> EventLoopFuture<Void> {
    database.schema("acronym-category-pivot").delete()
  }
}

extension AcronymCategoryPivot {
    enum v20210113 {
        static let schemaName = "acronym-category-pivot"
        static let id = FieldKey(stringLiteral: "id")
        static let acronymID = FieldKey(stringLiteral: "acronymID")
        static let categoryID = FieldKey(stringLiteral: "categoryID")
    }
}
