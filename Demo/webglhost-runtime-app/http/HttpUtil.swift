import Foundation
import webglhost_runtime

// MARK: - Token

private struct Token: Codable {
  let token: String
}

// MARK: - HttpUtil

public class HttpUtil {

  public static func getHostServerGameList(completion: @escaping ([GameModel]?, Error?) -> Void) {
    let baseURL = URL(string: Config.HOST_SERVER_API_BASE + "/game/list")!
    let queryItems = [
      URLQueryItem(name: "appId", value: Config.APP_ID),
    ]

    var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false)
    components?.queryItems = queryItems

    guard let modifiedURL = components?.url else {
      TJLogger.error("[\(Config.APP_LOG_TAG)] Failed to create URL with query parameters")
      return
    }

    var request = URLRequest(url: modifiedURL)
    request.httpMethod = "GET"
    request.setValue("Bearer \(Config.APP_SERVICE_TOKEN)", forHTTPHeaderField: "Authorization")

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

}
