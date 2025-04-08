import UIKit
import webglhost_runtime

// MARK: - MoreGamesViewController

class MoreGamesViewController: BaseViewController {

  // MARK: Lifecycle

  init(games: [PlayedGameModel]) {
    self.games = games
    super.init(nibName: nil, bundle: nil)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  override func viewDidLoad() {
    super.viewDidLoad()
    hidesCustomTabBar = true
    navigationController?.delegate = self
    setupUI()
    setupNavigationBar()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    navigationController?.setNavigationBarHidden(false, animated: animated)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    navigationController?.setNavigationBarHidden(true, animated: animated)
    restoreTabBarIfNeeded(animated: animated)
  }

  // MARK: Private

  private var games: [PlayedGameModel] = []

  private lazy var tableView: UITableView = {
    let tv = UITableView()
    tv.register(GameTableViewCell.self, forCellReuseIdentifier: GameTableViewCell.reuseIdentifier)
    tv.dataSource = self
    tv.delegate = self
    tv.separatorStyle = .none
    tv.rowHeight = 88
    return tv
  }()


  private func setupUI() {
    title = "最近游玩"
    view.backgroundColor = .white
    view.addSubview(tableView)
    tableView.snp.makeConstraints {
      $0.edges.equalTo(view.safeAreaLayoutGuide)
    }
  }

  private func setupNavigationBar() {
    title = "最近游玩"
    navigationController?.navigationBar.tintColor = .white
    navigationController?.navigationBar.barTintColor = .white

    let backButton = UIBarButtonItem(
      image: UIImage(named: "back-arrow")?.withRenderingMode(.alwaysOriginal),
      style: .plain,
      target: self,
      action: #selector(backAction))
    navigationItem.leftBarButtonItem = backButton
  }

  @objc
  private func backAction() {
    navigationController?.popViewController(animated: true)
  }
}

// MARK: UITableViewDataSource

extension MoreGamesViewController: UITableViewDataSource {
  func tableView(_: UITableView, numberOfRowsInSection _: Int) -> Int {
    games.count
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(
      withIdentifier: GameTableViewCell.reuseIdentifier,
      for: indexPath) as! GameTableViewCell
    cell.configure(recentlyPlayedGame: games[indexPath.row])
    return cell
  }
}

// MARK: UITableViewDelegate

extension MoreGamesViewController: UITableViewDelegate {
  func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    let game = games[indexPath.row]
    let model = GameModel(
      id: game.id,
      appId: game.id,
      bundleId: game.bundleId,
      gameType: game.gameType,
      name: game.name,
      tags: game.tags,
      iconUrl: game.iconUrl,
      briefIntro: game.briefIntro,
      versionId: game.versionId,
      launchKey: game.launchKey)
    (navigationController?.viewControllers.first as? ViewController)?.play(in: model)
    tableView.deselectRow(at: indexPath, animated: true)
  }
}
