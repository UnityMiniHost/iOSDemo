import Foundation
import webglhost_runtime

// MARK: - Token

private struct Token: Codable {
  let token: String
}

// MARK: - HttpUtil

public class HttpUtil {

  // MARK: Public

  public static func getHostServerGameList(completion: @escaping ([GameModel]?, Error?) -> Void) {
    let url = URL(string: GET_GAME_LIST_URL)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    let token = Token(token: Config.APP_SERVICE_TOKEN)

    do {
      let jsonData = try JSONEncoder().encode(token)
      request.httpBody = jsonData
    } catch {
      TJLogger.error("[\(Config.APP_LOG_TAG)] Encode error: \(error)")
      return
    }

    let task = URLSession.shared.dataTask(with: request) { data, _, error in
      if let error {
        TJLogger.error("[\(Config.APP_LOG_TAG)] Get game list failed: \(error)")
        return
      }
      guard let data else {
        TJLogger.error("[\(Config.APP_LOG_TAG)] No data received")
        return
      }
      do {
        if let bodyString = String(data: data, encoding: .utf8) {
          TJLogger.info("[\(Config.APP_LOG_TAG)] Response Body: \(bodyString)")
        }
        let games = try JSONDecoder().decode([GameModel].self, from: data)
        DispatchQueue.main.async {
          completion(games, nil)
        }
      } catch {
        TJLogger.error("[\(Config.APP_LOG_TAG)] Decode json error: \(error.localizedDescription)")
      }
    }

    task.resume()
  }

  // MARK: Private

  private static let GET_GAME_LIST_URL = Config.HOST_SERVER_API_BASE + "/game/get_list"

}
