import UIKit
import webglhost_runtime

// MARK: - HostViewControllerDelegate

protocol HostViewControllerDelegate: AnyObject {
  func startHostViewController(launchKey: String)
}

// MARK: - HostViewController

class HostViewController: UIViewController, GameBottomSheetViewControllerDelegate {
  var demoView: UIViewController?
  var gameView: UIViewController?
  var game: GameModel? // 列表启动相关参数
  var gameId: String? // 实例id (多实例相关)
  var launchKey: String? // 游戏启动参数

  var hostHandle: TJHostHandle?
  var gameHandle: RuntimeGameHandle?

  weak var delegate: HostViewControllerDelegate?

  override func viewDidLoad() {
    super.viewDidLoad()

    guard let _ = hostHandle, let _ = launchKey else {
      TJLogger.error("[\(Config.APP_LOG_TAG)] Unable to load game.")
      closeGameWithError()
      return
    }

    initHostView()

    initGameHandle()
  }

  override func viewWillAppear(_: Bool) {
    // 设置热启动进入参数
    let enterOption = MiniGameLaunchOption.Builder()
      .scene(1001)
      .build()
    if let gameId {
      // 多实例恢复游戏
      MultiGameLauncher.resume(gameId: gameId, enterOption)
    } else if let gameHandle, gameHandle.getGameState() == .running {
      gameHandle.setEnterOptions(enterOption)
      gameHandle.play()
    }
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    changeOrientation(orientation: .portrait) { _ in
      TJLogger.debug("[\(Config.APP_LOG_TAG)] Reset orientation success")
    }
  }

  @objc
  func changeOrientation(orientation: UIInterfaceOrientation, resultCallback: @escaping (Bool) -> Void) {
    let orientationMask: UIInterfaceOrientationMask =
      switch orientation {
      case .landscapeRight: .landscapeRight
      case .landscapeLeft: .landscapeLeft
      default: .portrait
      }

    guard let kAppdelegate = UIApplication.shared.delegate as? AppDelegate else {
      resultCallback(false)
      return
    }
    kAppdelegate.orientationMask = orientationMask

    if #available(iOS 16.0, *) {
      self.setNeedsUpdateOfSupportedInterfaceOrientations()
      guard let scence = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
        resultCallback(false)
        return
      }
      let geometryPreferences = UIWindowScene.GeometryPreferences.iOS(
        interfaceOrientations: orientationMask)
      scence.requestGeometryUpdate(geometryPreferences)
      resultCallback(true)
    } else {
      UIView.animate(withDuration: 0.3, animations: {
        UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        UIViewController.attemptRotationToDeviceOrientation()
      }, completion: { _ in
        resultCallback(true)
      })
    }
  }

  /// 初始化自定义游戏区域
  func initHostView() {
    guard Config.APP_ENABLE_CUSTOM_GAME_AREA else {
      TJLogger.debug("\(Config.APP_LOG_TAG) use fullscreen game view")
      return
    }

    let demoView = UIViewController()
    let gameView = UIViewController()

    view.addSubview(demoView.view)
    view.addSubview(gameView.view)

    let demoLabel = UILabel()
    demoLabel.text = "Non-gameing areas"
    demoLabel.textColor = UIColor(hexString: Config.APP_ENABLE_TRANSPARENT ? "#FFFFFF" : "#000000")

    demoView.view.backgroundColor = Config.APP_ENABLE_TRANSPARENT ? .black.withAlphaComponent(0.6) : .gray
    demoView.view.addSubview(demoLabel)

    demoView.view.snp.makeConstraints { make in
      make.height.equalToSuperview().multipliedBy(0.3)
      make.width.equalToSuperview()
      make.top.equalToSuperview()
    }

    gameView.view.snp.makeConstraints { make in
      make.height.equalToSuperview().multipliedBy(0.7)
      make.width.equalToSuperview()
      make.top.equalTo(demoView.view.snp.bottom)
    }
    demoLabel.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.centerY.equalToSuperview()
    }

    self.gameView = gameView
    self.demoView = demoView
  }

  /// 页面加载完成后初始化游戏宿主
  /// * 指定 game id 会匹配 MultiGameLauncher 中对应的宿主
  /// * 未指定 game id 时会创建新的宿主 hostHandle.createGameHandle(self)
  /// 初始化时需指定宿主关联的页面
  func initGameHandle() {
    if let hostHandle {
      if let gameId, !gameId.isEmpty {
        MultiGameLauncher.createGameHandle(hostHandle, gameId, gameView ?? self) { gameHandle, err in
          guard let gameHandle else {
            self.closeGameWithError(err: err)
            return
          }

          self.gameHandle = gameHandle
          self.setGameStartOptions()
        }
      } else {
        hostHandle.createGameHandle(self) { gameHandle, err in
          guard let gameHandle else {
            self.closeGameWithError(err: err)
            return
          }

          self.gameHandle = gameHandle
          self.setGameStartOptions()
        }
      }
    }
  }

  /// 宿主初始化完成后需设置启动参数
  /// 启动参数中  LAUNCH_KEY 作为启动的游戏传入
  /// 其他参数均为可选项
  func setGameStartOptions() {
    guard let gameHandle, let launchKey else {
      closeGameWithError()
      return
    }


    var options: [String: Any] = [
      TJConstants.LAUNCH_KEY: launchKey, // 设置启动参数 (必填)
      TJConstants.USER_ID: Config.USER_ID, // 设置游戏用户 (必填)
    ]


    initGameHandleListener()

    // 启用调试
    options[TJConstants.ENABLE_VCONSOLE] = Config.APP_DEBUG_MODE
    options[TJConstants.ENABLE_INSPECTOR] = Config.APP_DEBUG_MODE
    options[TJConstants.INSPECTOR_WAIT_FOR_INSPECT] = Config.APP_DEBUG_MODE

    options[TJConstants.ENABLE_MUTE_ALL_AUDIO] = Config.APP_MUTE_AUDIO
    options[TJConstants.ENABLE_TRANSPARENT_MODE] = Config.APP_ENABLE_TRANSPARENT // 高性能+ 暂不支持透明背景模式

    options[TJConstants.ENABLE_DOMAIN_WHITELIST] = false
    options[TJConstants.DOMAIN_WHITELIST_REQUEST] = [
      "https://jsonplaceholder.typicode.com",
      "https://www.unity.cn:8888",
      "https://reqres.in",
    ]
    options[TJConstants.DOMAIN_WHITELIST_REQUEST] = [
      "udp://www.baidu.com",
    ]

    // 设置自定义脚本
    options[TJConstants.CUSTOM_SCRIPT_FILES] = getCustomScripts()
    options[TJConstants.CUSTOM_SCRIPT_CONTENTS] = []

    // 设置游戏启动参数
    options[TJConstants.GAME_LAUNCH_OPTION] = MiniGameLaunchOption.Builder()
      .scene(1001)
      .build()
    options[TJConstants.ALWAYS_DOWNLOAD_PACKAGE] = false

    // 设置 splash 相关
    options[TJConstants.SHOW_MENU_EXPLORE_BTN] = true
    options[TJConstants.SHOW_MENU_LAYOUT] = true
    options[TJConstants.SPLASH_GAME_TITLE] = game?.name
    options[TJConstants.SPLASH_ICON_URL] = game?.iconUrl

    gameHandle.setGameStartOptions(options: options) { error in
      guard error == nil else {
        self.closeGameWithError(err: error)
        return
      }

      self.startGame()
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

      // 暂停游戏，重新进入游戏可继续
      if let gameId = self.gameId {
        MultiGameLauncher.pause(gameId: gameId)
      } else {
        gameHandle.pause()
      }

      // 停止游戏，重新进入游戏需重新加载
//        if let gameId = self.gameId {
//            MultiGameLauncher.stop(gameId: gameId)
//        } else {
//            gameHandle.stop()
//        }

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

    gameHandle.setOnGameChangeOrientationListener(changeOrientation)
  }

  /// 启动游戏
  func startGame() {
    if let gameHandle {
      gameHandle.start(onShowMsg: "start game") { error in
        guard error == nil else {
          self.closeGameWithError(err: error)
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
        handle.success(result: ["username": Config.USER_ID, "code": Config.USER_CODE_MOCK])
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

  func closeGameWithError(err: Error? = nil) {
    // 销毁游戏时: 如果游戏通过 MultiGameLauncher 启动需通过 MultiGameLauncher 来销毁对应的页面
    if let gameId {
      MultiGameLauncher.stop(gameId: gameId)
    } else {
      gameHandle?.stop()
    }

    var message = "打开游戏失败: \(err?.localizedDescription ?? "failed")"
    if let runtimeError = err as? HostRuntimeError, runtimeError == .GAME_NOT_AVAILABLE {
      switch runtimeError {
      case .GAME_NOT_AVAILABLE:
        message = "游戏未关联, 无法打开"
        break

      default:
        break
      }
    }
    showToast(message: message, seconds: 2) {
      self.dismiss(animated: true)
    }
  }

  func restartGame(_: GameBottomSheetViewController) {
    // 销毁游戏时: 如果游戏通过 MultiGameLauncher 启动需通过 MultiGameLauncher 来销毁对应的页面
    if let gameId {
      MultiGameLauncher.stop(gameId: gameId)
    } else {
      gameHandle?.stop()
    }
    dismiss(animated: false, completion: { [weak self] in
      guard let self else { return }
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        if let launchKey = self.launchKey {
          self.delegate?.startHostViewController(launchKey: launchKey)
        }
      }
    })
  }


  func toggleDebugMode(_ gameBottomSheetViewController: GameBottomSheetViewController) {
    Config.debugModeToggle()
    restartGame(gameBottomSheetViewController)
  }

  func exportLogManagerLog(_: GameBottomSheetViewController) {
    gameHandle?.exportLogManagerLog()
  }

  func showToast(message: String, seconds: TimeInterval, completion: @escaping () -> Void) {
    let completion = completion
    let toast = UIView()
    let toastContent = UILabel()

    toast.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    toast.layer.cornerRadius = 4
    toast.clipsToBounds = true
    toast.alpha = 0

    toastContent.textColor = .white
    toastContent.textAlignment = .center
    toastContent.text = message
    toastContent.numberOfLines = 0

    toast.addSubview(toastContent)
    view.addSubview(toast)


    toast.snp.makeConstraints { make in
      make.centerX.equalToSuperview()
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-20)
      make.width.lessThanOrEqualTo(view).multipliedBy(0.8)
    }

    toastContent.snp.makeConstraints { make in
      make.edges.equalTo(toast).inset(UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8))
    }

    UIView.animate(withDuration: 0.5, animations: {
      toast.alpha = 1
    }) { _ in
      DispatchQueue.main.asyncAfter(deadline: .now() + seconds) {
        UIView.animate(withDuration: 0.5, animations: {
          toast.alpha = 0
        }) { _ in
          toast.removeFromSuperview()
          completion()
        }
      }
    }
  }

}
