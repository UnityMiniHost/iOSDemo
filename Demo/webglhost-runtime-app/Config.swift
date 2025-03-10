class Config {
  public static let HOST_SERVER_API_BASE = "https://minihost.tuanjie.cn/api"

  public static let APP_SERVICE_TOKEN =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJhcHBJZCI6IjY3YjZlZGEzNmZmY2RhMjU1OWVjZDM4OCIsImlkIjoiMTBhNGI1MzEtMWUxYy00ZWFlLWE2NWQtM2E3MWQ5OWYzYTRjIn0._24T3k-lVx2GQwAKg-RYhxD89EqSQP3Y10nzbd-JxHk"
  public static let SDK_KEY = "AKIDt1vMSYVFf1twI53iDecobx6QsTK0"
  public static let SDK_SECRET = "ufzN1iD8PsnMW0ViDCMhpJFBiLR1E1Xf"

  public static let APP_LOG_TAG = "app"

  public static var APP_DEBUG_MODE = false
  public static var APP_MUTE_AUDIO = false

  public static func debugModeToggle() {
    APP_DEBUG_MODE = !APP_DEBUG_MODE
  }
}
