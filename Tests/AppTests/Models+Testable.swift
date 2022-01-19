@testable import App
import Fluent
import Vapor

extension User {
  // 1
  static func create(
    name: String = "Luke",
    username: String? = nil,
    on database: Database
  ) throws -> User {
    let createUsername: String
    // 2
    if let suppliedUsername = username {
      createUsername = suppliedUsername
    // 3
    } else {
      createUsername = UUID().uuidString
    }

    // 4
    let password = try Bcrypt.hash("password")
    let user = User(
      name: name,
      username: createUsername,
      password: password,
      email: "\(createUsername)@test.com")
    try user.save(on: database).wait()
    return user
  }
}

extension Acronym {
  static func create(
    short: String = "TIL",
    long: String = "Today I Learned",
    user: User? = nil,
    on database: Database
  ) throws -> Acronym {
    var acronymsUser = user
    
    if acronymsUser == nil {
      acronymsUser = try User.create(on: database)
    }
    
    let acronym = Acronym(
      short: short,
      long: long,
      userID: acronymsUser!.id!)
    try acronym.save(on: database).wait()
    return acronym
  }
}

extension App.Category {
  static func create(
    name: String = "Random",
    on database: Database
  ) throws -> App.Category {
    let category = Category(name: name)
    try category.save(on: database).wait()
    return category
  }
}
