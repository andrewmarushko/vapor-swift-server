import Fluent
import Vapor

func routes(_ app: Application) throws {  
  app.get("hello") { req -> String in
    return "Hello, world!"
  }
  
  let acronymsController = AcronymsController()
  try app.register(collection: acronymsController)
  
  let usersController = UsersController()
  try app.register(collection: usersController)
  
  let categoriesController = CategoriesController()
  try app.register(collection: categoriesController)

  let websiteController = WebsiteController()
  try app.register(collection: websiteController)
    
    let impertialController = ImperialController()
    try app.register(collection: impertialController)

}
