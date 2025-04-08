class Config {
  public static var HOST_ORG_NAME = "Tuanjie MiniHost"
  public static var HOST_SERVER_API_BASE = "https://minihost.tuanjie.cn/api"

  public static var APP_ID = "67b6eda36ffcda2559ecd388"
  public static var APP_SERVICE_TOKEN =
    "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6ImRlMzc4ZWYxLTk2N2ItNDQ2OC1hNTY5LWQzOTQ1ZmY2NWM0YiIsInBsYXRmb3JtU2VydmVySWQiOiI2N2NmZDg5OThjMThhNWE2NGNiM2RiN2EifQ.SAM9uRiOYw9bcMeqnh2d7RIbWWqds8lVSIjSR_tUv4A"
  public static var SDK_KEY = "AKIDt1vMSYVFf1twI53iDecobx6QsTK0"
  public static var SDK_SECRET = "ufzN1iD8PsnMW0ViDCMhpJFBiLR1E1Xf"

  public static let APP_LOG_TAG = "app"

  public static var APP_DEBUG_MODE = false
  public static var APP_MUTE_AUDIO = false
  public static var APP_ENABLE_TRANSPARENT = true
  public static var APP_ENABLE_CUSTOM_GAME_AREA = false

  public static var USER_ID = "tuanjie"
  public static var USER_CODE_MOCK = "000000-000000-000000-000000"

  public static func debugModeToggle() {
    APP_DEBUG_MODE = !APP_DEBUG_MODE
  }

  public static func setHostConfig(_ host: HostModel) {
    HOST_ORG_NAME = host.org
    HOST_SERVER_API_BASE = host.domain
    APP_ID = host.id
    APP_SERVICE_TOKEN = host.token
    SDK_KEY = host.key
    SDK_SECRET = host.secret
    USER_ID = "tuanjie-\(host.id)"
  }
}
