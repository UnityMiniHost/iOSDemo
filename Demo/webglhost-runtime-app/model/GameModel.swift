import webglhost_runtime

public struct GameModel: Codable {
  var id = "" // 游戏 id
  var createdTime: String? = ""
  var updatedTime: String? = ""
  var appId: String? = ""
  var bundleId: String? = ""
  var gameType: String? = ""
  var name: String? = ""
  var tags: [String]? = [String]()
  var iconUrl: String? = ""
  var briefIntro: String? = ""
  var versionId: String? = ""
  var launchKey: String? = "" // 游戏启动参数
}
