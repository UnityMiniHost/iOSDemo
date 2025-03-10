public struct GameModel: Codable {
  var id = ""
  var createdTime: String? = ""
  var updatedTime: String? = ""
  var appId: String? = ""
  var gameType: String? = ""
  var name: String? = ""
  var tags: [String]? = [String]()
  var iconUrl: String? = ""
  var briefIntro: String? = ""
}
