import UIKit

// MARK: - GameBottomSheetViewControllerDelegate

protocol GameBottomSheetViewControllerDelegate: AnyObject {
  func restartGame(_ gameBottomSheetViewController: GameBottomSheetViewController)
  func toggleDebugMode(_ gameBottomSheetViewController: GameBottomSheetViewController)
  func exportLogManagerLog(_ gameBottomSheetViewController: GameBottomSheetViewController)
}

// MARK: - GameBottomSheetViewController

class GameBottomSheetViewController: BottomSheetViewController {

  // MARK: Internal

  weak var delegate: GameBottomSheetViewControllerDelegate?

  // MARK: - View Setup

  override func viewDidLoad() {
    super.viewDidLoad()
    setupView()
  }

  // MARK: - Func

  @objc
  func restartGame() {
    dismissBottomSheet(animated: false, completion: { [weak self] in
      self?.delegate?.restartGame(self!)
    })
  }

  @objc
  func openDebuggingToolkit() {
    setupViewForDevtool()
  }

  @objc
  func toggleDebugMode() {
    let alertController = UIAlertController(
      title: "Debug Mode Change Take Effect After Restart",
      message: "Press OK to Close Game",
      preferredStyle: .alert)

    let okAction = UIAlertAction(title: "OK", style: .default) { _ in
      self.dismissBottomSheet(animated: false, completion: { [weak self] in
        self?.delegate?.toggleDebugMode(self!)
      })
    }

    // Add the OK action to the alert controller
    alertController.addAction(okAction)

    // Present the alert controller
    if let presenter = alertController.popoverPresentationController {
      presenter.sourceView = view
      presenter.sourceRect = view.bounds
    }
    present(alertController, animated: true, completion: nil)
  }

  @objc
  func turnOnProfiler() { }

  @objc
  func requestForceGC() { }

  @objc
  func openCodeDebug() { }

  @objc
  func showVersionInfo() { }

  @objc
  func startCpuProfile() { }

  @objc
  func dumpMemory() { }

  @objc
  func exportLogManagerLog() {
    delegate?.exportLogManagerLog(self)
  }

  // MARK: Private

  // MARK: - UI

  private lazy var contentView: UIStackView = {
    let view = UIStackView()
    view.axis = .vertical
    return view
  }()

  private lazy var restartButton: UIButton = {
    let button = UIButton()
    button.backgroundColor = self.contentColor
    button.addTarget(self, action: #selector(restartGame), for: .touchUpInside)

    button.setTitle("重新进入小游戏", for: .normal)
    button.setTitleColor(self.textColor, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    button.titleLabel?.snp.makeConstraints { make in
      make.left.equalTo(button).offset(12)
      make.centerY.equalTo(button)
    }

    let imageView = UIImageView()
//    imageView.image = UIImage.iconRedo
    button.addSubview(imageView)
    imageView.snp.makeConstraints { make in
      make.width.height.equalTo(24)
      make.right.equalTo(button).offset(-12)
      make.centerY.equalTo(button)
    }

    return button
  }()

  private lazy var debuggingToolkitButton: UIButton = {
    let button = UIButton()
    button.backgroundColor = self.contentColor
    button.addTarget(self, action: #selector(openDebuggingToolkit), for: .touchUpInside)

    button.setTitle("开发调试", for: .normal)
    button.setTitleColor(self.textColor, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    button.titleLabel?.snp.makeConstraints { make in
      make.left.equalTo(button).offset(12)
      make.centerY.equalTo(button)
    }

    let imageView = UIImageView()
//    imageView.image = UIImage.iconDev
    button.addSubview(imageView)
    imageView.snp.makeConstraints { make in
      make.width.height.equalTo(24)
      make.right.equalTo(button).offset(-12)
      make.centerY.equalTo(button)
    }

    return button
  }()

  private lazy var toggleDebugModeButton: UIButton = {
    let button = UIButton()
    let debugMode = Config.APP_DEBUG_MODE
    button.setTitle(debugMode ? "关闭调试" : "打开调试", for: .normal)
    button.setTitleColor(self.textColor, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    button.backgroundColor = self.contentColor
    button.layer.cornerRadius = 12
    button.clipsToBounds = true
    button.addTarget(self, action: #selector(toggleDebugMode), for: .touchUpInside)

    return button
  }()

  private lazy var versionInfoButton: UIButton = {
    let button = UIButton()
    button.setTitle("版本信息", for: .normal)
    button.setTitleColor(self.textColor, for: .normal)
    button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
    button.backgroundColor = self.contentColor
    button.layer.cornerRadius = 12
    button.clipsToBounds = true
    button.addTarget(self, action: #selector(showVersionInfo), for: .touchUpInside)

    return button
  }()

  private lazy var firstLineStackView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [toggleDebugModeButton])
    stackView.axis = .horizontal
    stackView.spacing = 8
    stackView.distribution = .fillEqually
    stackView.backgroundColor = self.backgroundColor
    return stackView
  }()

  private lazy var menuTitle: UILabel = {
    let title = UILabel()
    title.font = .systemFont(ofSize: 16)
    title.textColor = self.textColor
    title.textAlignment = .center
    return title
  }()

  private lazy var titleView: UIStackView = {
    let stackView = UIStackView(arrangedSubviews: [menuTitle])
    stackView.axis = .horizontal
    stackView.distribution = .fill
    stackView.alignment = .center
    return stackView
  }()

  private func setupView() {
    contentView.spacing = 1
    contentView.layer.cornerRadius = 12
    contentView.clipsToBounds = true

    contentView.addArrangedSubview(restartButton)
    restartButton.snp.makeConstraints { make in
      make.height.equalTo(52)
    }

    contentView.addArrangedSubview(debuggingToolkitButton)
    debuggingToolkitButton.snp.makeConstraints { make in
      make.height.equalTo(52)
    }

    setContent(content: contentView)

    menuTitle.text = "游戏信息"
    setTitleView(titleView: titleView)
  }

  private func setupViewForDevtool() {
    contentView.removeArrangedSubview(restartButton)
    contentView.removeArrangedSubview(debuggingToolkitButton)

    contentView.backgroundColor = backgroundColor
    contentView.spacing = 8

    contentView.addArrangedSubview(firstLineStackView)
    firstLineStackView.snp.makeConstraints { make in
      make.height.equalTo(60)
    }

    setContent(content: contentView)

    titleView.removeArrangedSubview(menuTitle)
    menuTitle.text = "开发调试"
    titleView.addArrangedSubview(menuTitle)
    setTitleView(titleView: titleView)
  }
}
