import UIKit
import webglhost_runtime

// MARK: - HostViewControllerDelegate

protocol HostViewControllerDelegate: AnyObject {
  func startHostViewController(gameModel: GameModel)
  func startHostViewController(sessionUrl: String)
}

// MARK: - HostViewController

class HostViewController: UIViewController, GameBottomSheetViewControllerDelegate {
  var game: GameModel?
  var sessionUrl: String?

  var hostHandle: TJHostHandle?
  var gameHandle: RuntimeGameHandle?

  weak var delegate: HostViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    guard let _ = hostHandle, let _ = game?.id ?? sessionUrl else {
      TJLogger.error("[\(Config.APP_LOG_TAG)] Unable to load game.")
      dismiss(animated: true)
      return
    }

    initGameHandle()
  }

  override func viewWillAppear(_: Bool) {
    // 设置热启动进入参数
    if let gameHandle, gameHandle.getGameState() == .running {
      gameHandle.setEnterOptions(
        MiniGameLaunchOption.Builder()
          .scene(1002)
          .shareTicket("1002")
          .build())
      gameHandle.play()
    }
  }

  /// 页面加载完成后初始化游戏宿主
  /// * 指定 game id 会匹配 MultiGameLauncher 中对应的宿主
  /// * 未指定 game id 时会创建新的宿主 hostHandle.createGameHandle(self)
  /// 初始化时需指定宿主关联的页面
  func initGameHandle() {
    if let hostHandle {
      let gameId: String = game?.id ?? sessionUrl ?? ""
      if !gameId.isEmpty {
        hostHandle.createGameHandle(gameId, self) { gameHandle, _ in
          guard let gameHandle else {
            return
          }

          self.gameHandle = gameHandle
          self.setGameStartOptions()
        }
      }
    }
  }

  /// 宿主初始化完成后需设置启动参数
  /// 启动参数中 GAME_ID 和 GAME_SESSION_URL 至少选择一个作为启动的游戏传入
  /// 其他参数均为可选项
  func setGameStartOptions() {
    if let gameHandle {
      var options: [String: Any]?
      if let game {
        options = [
          TJConstants.GAME_ID: game.id,
        ]
      }
      if let sessionUrl {
        options = [
          TJConstants.GAME_SESSION_URL: sessionUrl,
        ]
      }

      guard var options else {
        return
      }

      initGameHandleListener()

      options[TJConstants.ENABLE_VCONSOLE] = Config.APP_DEBUG_MODE
      options[TJConstants.ENABLE_INSPECTOR] = Config.APP_DEBUG_MODE
      options[TJConstants.INSPECTOR_WAIT_FOR_INSPECT] = Config.APP_DEBUG_MODE
      options[TJConstants.ENABLE_MUTE_ALL_AUDIO] = Config.APP_MUTE_AUDIO
      options[TJConstants.ENABLE_DOMAIN_WHITELIST] = false
      options[TJConstants.DOMAIN_WHITELIST_REQUEST] = [
        "https://jsonplaceholder.typicode.com",
        "https://www.unity.cn:8888",
        "https://reqres.in",
      ]
      options[TJConstants.DOMAIN_WHITELIST_REQUEST] = [
        "udp://www.baidu.com",
      ]

      options[TJConstants.CUSTOM_SCRIPT_FILES] = getCustomScripts()
      options[TJConstants.GAME_LAUNCH_OPTION] = MiniGameLaunchOption.Builder()
        .scene(1001)
        .appId("1001")
        .build()
      options[TJConstants.ALWAYS_DOWNLOAD_PACKAGE] = true
      options[TJConstants.SHOW_MENU_EXPLORE_BTN] = true
      options[TJConstants.SPLASH_GAME_TITLE] = game?.name
      options[TJConstants.SPLASH_ICON_URL] = game?.iconUrl
      gameHandle.setGameStartOptions(options: options) { error in
        guard error == nil else {
          return
        }

        self.startGame()
      }
    }
  }

  /// 初始化宿主监听事件
  func initGameHandleListener() {
    guard let gameHandle else {
      return
    }

    gameHandle.setOnTJMenuListener {
      TJLogger.debug("[\(Config.APP_LOG_TAG)] OnTJMenuListener")
      let vc = GameBottomSheetViewController()
      vc.setMenuStyle(style: "dark")
      vc.delegate = self
      self.presentBottomSheet(viewController: vc)
    }

    gameHandle.setOnTJCloseListener {
      TJLogger.debug("[\(Config.APP_LOG_TAG)] OnTJCloseListener")
      self.gameHandle?.pause()

      // Destroy game
      // self.gameHandle?.destroy()

      self.dismiss(animated: true)
    }

    gameHandle.setOnGamePackageDownloadListener(
      onStart: {
        TJLogger.debug("[\(Config.APP_LOG_TAG)] OnGamePackageDownloadListener: onStart")
      },
      onProgress: { _, downloadSize, packageSize in
        TJLogger.debug("[\(Config.APP_LOG_TAG)] OnGamePackageDownloadListener: onProgress \(downloadSize), \(packageSize)")
      },
      onSuccess: {
        TJLogger.debug("[\(Config.APP_LOG_TAG)] OnGamePackageDownloadListener: onSuccess")
      },
      onFailure: { error in
        if let error {
          TJLogger.debug("[\(Config.APP_LOG_TAG)] OnGamePackageDownloadListener: onFailure \(error.localizedDescription)")
        }
      })

    gameHandle.setOnFirstFrameRenderedListener {
      TJLogger.debug("[\(Config.APP_LOG_TAG)] OnFirstFrameRenderedListener")
    }
  }

  /// 启动游戏
  func startGame() {
    if let gameHandle {
      gameHandle.start(onShowMsg: "start game") { error in
        guard error == nil else {
          return
        }

        self.setCustomCommandListeners()

        gameHandle.play()
      }
    }
  }

  func setCustomCommandListeners() {
    initAdListener()
    initAuthListener()
  }

  func initAdListener() {
    guard let gameHandle else {
      return
    }

    gameHandle.setCustomCommandListener("loadRewardAd") { _, handle in
      // Load ad
      guard let gameHandle = self.gameHandle else {
        return
      }

      handle.success(result: [:])

      gameHandle.runCustomScript("""
            rewardedVideoLoadCallback();
        """) { _, _ in
        TJLogger.debug("[\(Config.APP_LOG_TAG)] load success ad.")
      }
    }

    gameHandle.setCustomCommandListener("showRewardAd") { _, handle in
      guard let gameHandle = self.gameHandle else {
        return
      }

      handle.success(result: [:])

      gameHandle.runCustomScript("""
            rewardedVideoCloseCallback(true);
        """) { _, _ in
        TJLogger.debug("[\(Config.APP_LOG_TAG)] close reward video ad.")
      }
    }
  }

  func initAuthListener() {
    guard let gameHandle else {
      return
    }

    gameHandle.setCustomCommandListener("TJLoginHost") { request, handle in
      guard let username = request["username"] as? String else {
        handle.fail(errorCode: 20001, errorMsg: "invalid username")
        return
      }

      // 延迟返回结果，模拟异步请求
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        handle.success(result: ["username": username + "_login", "age": 18])
      }
    }
  }

  func getCustomScripts() -> [String] {
    var files: [String] = []

    if
      let authJsUrl = Bundle(for: type(of: self)).url(
        forResource: "auth",
        withExtension: "js")
    {
      files.append(authJsUrl.path)
    }

    if
      let adJsUrl = Bundle(for: type(of: self)).url(
        forResource: "ad",
        withExtension: "js")
    {
      files.append(adJsUrl.path)
    }

//    if
//      let mockUIJsUrl = Bundle(for: type(of: self)).url(
//        forResource: "mock_ui",
//        withExtension: "js")
//    {
//      files.append(mockUIJsUrl.path)
//    }

    return files
  }

  func restartGame(_: GameBottomSheetViewController) {
    gameHandle?.destroy()
    dismiss(animated: false, completion: { [weak self] in
      guard let self else { return }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        if let gameModel = self.game {
          self.delegate?.startHostViewController(gameModel: gameModel)
        }
        if let sessionUrl = self.sessionUrl {
          self.delegate?.startHostViewController(sessionUrl: sessionUrl)
        }
      }
    })
  }


  func toggleDebugMode(_: GameBottomSheetViewController) {
    Config.debugModeToggle()
  }

  func exportLogManagerLog(_: GameBottomSheetViewController) {
    gameHandle?.exportLogManagerLog()
  }

}
