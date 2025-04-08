import SDWebImage
import SnapKit
import UIKit
import webglhost_runtime

// MARK: - ViewController

class ViewController: UIViewController {

  // MARK: Lifecycle

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  // MARK: Internal

  let itemHeight: CGFloat = 30.0
  let itemSpacing: CGFloat = 10.0
  var addedSubviews: [UIView] = []

  lazy var headerView = UIView()
  lazy var recentlyView = UIView()
  lazy var bottomView = UIStackView()
  lazy var listHeaderView = UIView()
  lazy var tableView = UITableView()

  var initialized = false
  var hostHandle: TJHostHandle?

  override func viewDidLoad() {
    super.viewDidLoad()

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleAppWillTerminate),
      name: UIApplication.willTerminateNotification,
      object: nil)

    initTJHostHandle()
    getHostServerGameList()
    setupUI()
    layoutUI()
    setupNotificationObserver()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(true, animated: animated)
  }

  @objc
  func handleAppWillTerminate() {
    MultiGameLauncher.destroyAll()
  }

  func setupUI() {
    view.backgroundColor = .white
    setupHeader()
    setupRecentlyView()
    setupListHeaderView()
    setupTableView()
  }

  func setupHeader() {
    let imageView = UIImageView()
    imageView.image = UIImage(named: "header")
    imageView.contentMode = .scaleToFill
    headerView.addSubview(imageView)

    let titleLabel = UILabel()
    titleLabel.text = "Unity小游戏宿主"
    titleLabel.textColor = .white
    titleLabel.font = UIFont.systemFont(ofSize: 24, weight: .bold)
    headerView.addSubview(titleLabel)

    let scanView = HostScanUIView()
    headerView.addSubview(scanView)

    view.addSubview(headerView)

    imageView.snp.makeConstraints { make in
      make.height.equalTo(150)
      make.edges.equalToSuperview()
    }

    titleLabel.snp.makeConstraints { make in
      make.left.equalToSuperview().inset(16)
      make.bottom.equalToSuperview().inset(22)
    }

    scanView.snp.makeConstraints { make in
      make.width.equalTo(20)
      make.right.equalToSuperview().inset(6)
      make.top.equalToSuperview().inset(16)
    }
  }

  func setupRecentlyView() {
    recentlyView.backgroundColor = .white
    view.addSubview(recentlyView)

    let topView = UIStackView()
    topView.axis = .horizontal
    topView.distribution = .fill
    recentlyView.addSubview(topView)

    let titleLabel = UILabel()
    titleLabel.text = "最近游玩"
    titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
    titleLabel.textColor = UIColor(hexString: "#666666")

    let moreButton = UIButton()
    moreButton.setTitle("更多", for: .normal)
    moreButton.setTitleColor(UIColor(hexString: "#666666"), for: .normal)
    moreButton.setImage(UIImage(named: "arrow"), for: .normal)
    moreButton.semanticContentAttribute = .forceRightToLeft // 文字在左，图标在右
    moreButton.titleLabel?.font = UIFont.systemFont(ofSize: 12)
    moreButton.addTarget(self, action: #selector(showMoreGames), for: .touchUpInside)

    topView.addArrangedSubview(titleLabel)
    topView.addArrangedSubview(moreButton)

    let bottomView = UIStackView()
    bottomView.axis = .horizontal
    bottomView.spacing = 32
    bottomView.alignment = .center
    recentlyView.addSubview(bottomView)

    topView.snp.makeConstraints { make in
      make.top.equalToSuperview().inset(12)
      make.left.right.equalToSuperview().inset(16)
      make.height.equalTo(24)
    }

    bottomView.snp.makeConstraints { make in
      make.top.equalTo(topView.snp.bottom).offset(8)
      make.left.right.equalToSuperview().inset(16)
      make.bottom.equalToSuperview().inset(12)
    }

    recentlyView.isHidden = true
    recentlyView.snp.remakeConstraints { make in
      make.height.equalTo(0)
    }

    self.bottomView = bottomView
  }

  func setupListHeaderView() {
    view.addSubview(listHeaderView)

    let titleLabel = UILabel()
    titleLabel.text = "所有游戏"
    titleLabel.font = UIFont.systemFont(ofSize: 12, weight: .regular)
    titleLabel.textColor = UIColor(hexString: "#666666")



    listHeaderView.addSubview(titleLabel)

    titleLabel.snp.makeConstraints { make in
      make.left.equalTo(16)
      make.centerY.equalToSuperview()
    }
  }

  func setupTableView() {
    tableView.register(GameTableViewCell.self, forCellReuseIdentifier: GameTableViewCell.reuseIdentifier)
    tableView.dataSource = self
    tableView.delegate = self
    tableView.separatorStyle = .none
    view.addSubview(tableView)
  }

  func layoutUI() {
    headerView.snp.makeConstraints { make in
      make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
      make.left.right.equalToSuperview().inset(16)
    }

    recentlyView.snp.makeConstraints { make in
      make.top.equalTo(headerView.snp.bottom)
      make.left.right.equalToSuperview()
      make.height.equalTo(126)
    }

    listHeaderView.snp.makeConstraints { make in
      make.top.equalTo(recentlyView.snp.bottom)
      make.left.right.equalToSuperview()
      make.height.equalTo(46)
    }

    tableView.snp.makeConstraints { make in
      make.top.equalTo(listHeaderView.snp.bottom)
      make.left.right.equalToSuperview()
      make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-49)
    }
  }

  /// 初始化SDK，多实例数量设置，日志输出设置
  func initTJHostHandle() {
    MultiGameLauncher.configMaxGame(max: 3) // 初始化多实例最大启动数量，默认数量为 1
    TJHostHandle.initialize(
      sdkKey: Config.SDK_KEY,
      sdkSecret: Config.SDK_SECRET)
    { hostHandle, _ in
      guard let hostHandle else {
        return
      }

      hostHandle.initLog(.debug, self)

      hostHandle.setRecentlyPlayedGameDelegate(delegate: self)

      self.hostHandle = hostHandle
    }
  }

  /// 启动游戏页面
  /// - Parameter
  ///   gameId: 实例 id
  ///   binding: 绑定实例相关信息
  func launchHostView(gameId: String, binding: @escaping (HostViewController) -> Void) {
    guard let hostHandle else {
      return
    }

    let hostViewController = MultiGameLauncher.launch(gameId: gameId, HostViewController.self)
    hostViewController.gameId = gameId
    hostViewController.hostHandle = hostHandle
    hostViewController.modalPresentationStyle = Config.APP_ENABLE_TRANSPARENT ? .overFullScreen : .fullScreen
    hostViewController.delegate = self
    binding(hostViewController)

    present(hostViewController, animated: true, completion: {
      // 记录游戏启动信息
      let playedGames = hostHandle.getAllRecentlyPlayedGames(userId: Config.USER_ID)
      self.addGameViews(to: self.bottomView, games: playedGames)
    })
  }

  /// 通过 game 启动游戏
  func play(in game: GameModel) {
    launchHostView(gameId: game.launchKey ?? game.id) { hostViewController in
      hostViewController.launchKey = game.launchKey
    }
  }

  /// 通过扫码启动游戏
  func playGameWithScan(result url: String) {
    launchHostView(gameId: url) { hostViewController in
      hostViewController.launchKey = url
    }
  }

  func updateList(with newGames: [GameModel]) {
    guard let hostHandle else {
      return
    }
    games = newGames
    let playedGames = hostHandle.getAllRecentlyPlayedGames(userId: Config.USER_ID)
    addGameViews(to: bottomView, games: playedGames)
    tableView.reloadData()
  }

  func getHostServerGameList() {
    HttpUtil.getHostServerGameList(completion: { (items: [GameModel]?, error: Error?) in
      if error != nil {
        print("get host server game list error")
        return
      }
      self.updateList(with: items!)
    })
  }

  @objc
  func clickRecentlyPlayedGame(_ sender: UITapGestureRecognizer) {
    if let view = sender.view as? GameView {
      let model = GameModel(
        id: view.data!.id,
        appId: view.data!.id,
        bundleId: view.data!.bundleId,
        gameType: view.data!.gameType,
        name: view.data!.name,
        tags: view.data!.tags,
        iconUrl: view.data!.iconUrl,
        briefIntro: view.data!.briefIntro,
        versionId: view.data?.versionId,
        launchKey: view.data?.launchKey)
      play(in: model)
    }
  }

  // MARK: Private

  private var games: [GameModel] = []


  private func addGameViews(to container: UIStackView, games: [PlayedGameModel]) {
    for arrangedSubview in container.arrangedSubviews { arrangedSubview.removeFromSuperview() }

    let maxCount = 5
    let gameCount = min(games.count, maxCount)
    guard gameCount > 0 else { return }

    let screenWidth = UIScreen.main.bounds.width
    let availableWidth = screenWidth - 32 - 32

    let itemWidth = min(48, (availableWidth - CGFloat(gameCount-1)*32) / CGFloat(gameCount))

    if !games.isEmpty {
      recentlyView.isHidden = false
      recentlyView.snp.remakeConstraints { make in
        make.top.equalTo(headerView.snp.bottom)
        make.left.right.equalToSuperview()
        make.height.equalTo(126)
      }
    }

    for game in games.prefix(maxCount) {
      let gameView = GameView(game: game)
      let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(clickRecentlyPlayedGame))
      gameView.addGestureRecognizer(tapGestureRecognizer)
      container.addArrangedSubview(gameView)

      gameView.snp.makeConstraints { make in
        make.width.equalTo(itemWidth).priority(.high)
        make.height.equalTo(64)
      }
    }

    let spacer = UIView()
    container.addArrangedSubview(spacer)
    spacer.snp.makeConstraints { make in
      make.width.greaterThanOrEqualTo(0)
    }
  }

  private func setupNotificationObserver() {
    // 注册通知监听
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleScanResult(_:)),
      name: .didReceiveScanResult,
      object: nil)

    NotificationCenter.default.addObserver(
      self,
      selector: #selector(handleUpdateHostConfig(_:)),
      name: .didUpdateHostConfig,
      object: nil)
  }

  @objc
  private func handleScanResult(_ notification: Notification) {
    // 确保在主线程处理
    DispatchQueue.main.async { [weak self] in
      guard let scanResult = notification.object as? String else {
        print("收到无效的扫描结果")
        return
      }

      print("接收到扫描结果: \(scanResult)")
      // 在这里添加处理逻辑，例如：
//      self?.showScanResultAlert(result: scanResult)
      self?.playGameWithScan(result: scanResult)
    }
  }


  @objc
  private func handleUpdateHostConfig(_: Notification) {
    // 确保在主线程处理
    DispatchQueue.main.async { [weak self] in
      MultiGameLauncher.destroyAll()
      self?.initTJHostHandle()
      self?.getHostServerGameList()
    }
  }



  private func showScanResultAlert(result: String) {
    let alert = UIAlertController(
      title: "扫描结果",
      message: result,
      preferredStyle: .alert)
    alert.addAction(UIAlertAction(title: "确定", style: .default))
    present(alert, animated: true)
  }

  @objc
  private func showMoreGames() {
    guard let hostHandle else {
      return
    }
    let moreVC = MoreGamesViewController(games: hostHandle.getAllRecentlyPlayedGames(userId: Config.USER_ID))
    navigationController?.pushViewController(moreVC, animated: true)
  }
}

// MARK: RecentlyGameDelegate

extension ViewController: RecentlyGameDelegate {
  func updateGame(game _: webglhost_runtime.PlayedGameModel) {
    guard let hostHandle else {
      return
    }
    let playedGames = hostHandle.getAllRecentlyPlayedGames(userId: Config.USER_ID)
    addGameViews(to: bottomView, games: playedGames)
  }
}

// MARK: UITableViewDataSource

extension ViewController: UITableViewDataSource {
  func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    games.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: GameTableViewCell.reuseIdentifier,
      for: indexPath) as! GameTableViewCell
    cell.configure(with: games[indexPath.row])
    return cell
  }
}

// MARK: UITableViewDelegate

extension ViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let game = games[indexPath.row]
    play(in: game)
    tableView.deselectRow(at: indexPath, animated: true)
  }
}

// MARK: HostViewControllerDelegate

extension ViewController: HostViewControllerDelegate {
  func startHostViewController(launchKey: String) {
    launchHostView(gameId: launchKey) { hostViewController in
      hostViewController.launchKey = launchKey
    }
  }
}

// MARK: OnLogPrintListener

/// 监听宿主日志输出
extension ViewController: OnLogPrintListener {
  func printLog(level: TJLogLevel, msg: String) {
    var logMessage = ""

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
    let timestamp = dateFormatter.string(from: Date())
    logMessage += "[\(timestamp)] "

    switch level {
    case .info:
      logMessage += "[INFO] "
    case .debug:
      logMessage += "[DEBUG] "
    case .warning:
      logMessage += "[WARNING] "
    case .error:
      logMessage += "[ERROR] "
    default:
      logMessage += "[INFO] "
    }

    logMessage += msg

    print(logMessage)
  }
}

extension Notification.Name {
  static let didUpdateHostConfig = Notification.Name("SetHostConfig")
}
