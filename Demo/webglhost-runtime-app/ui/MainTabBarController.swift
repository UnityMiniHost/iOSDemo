import AVFoundation
import QRCodeReader
import UIKit

// MARK: - MainTabBarController

class MainTabBarController: UITabBarController {

  // MARK: Public

  public let customTabBar = CustomTabBar()

  // MARK: Internal

  lazy var qrScaner = QRScanner(view: self)

  override func viewDidLoad() {
    super.viewDidLoad()
    setupCustomTabBar()
    setupViewControllers()
    setupTabBarDelegate()
  }

  // MARK: Private

  private var tabBarHeight: CGFloat {
    let defaultHeight: CGFloat = 49
    return defaultHeight + view.safeAreaInsets.bottom
  }


  private func setupCustomTabBar() {
    tabBar.isHidden = true

    customTabBar.delegate = self
    view.addSubview(customTabBar)

    customTabBar.snp.makeConstraints {
      $0.leading.trailing.equalToSuperview()
      $0.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
      $0.height.equalTo(tabBarHeight)
    }

    let homeItem = TabItem(
      title: "主页",
      normalImage: UIImage(named: "game"),
      selectedImage: UIImage(named: "game-fill"))

    let scanItem = TabItem(
      title: "扫码",
      normalImage: UIImage(named: "qrscan"),
      selectedImage: UIImage(named: "qrscan-fill"))

    customTabBar.setupItems([homeItem, scanItem])
  }

  private func setupViewControllers() {
    let homeVC = ViewController()
    let scanPlaceholder = UIViewController() // 占位控制器

    viewControllers = [
      UINavigationController(rootViewController: homeVC),
      UINavigationController(rootViewController: scanPlaceholder),
    ]

    customTabBar.selectItem(at: 0)
  }

  private func setupTabBarDelegate() {
    customTabBar.delegate = self
  }
}

// MARK: CustomTabBarDelegate

extension MainTabBarController: CustomTabBarDelegate {
  func didSelectItem(at index: Int) {
    if index == 1 {
      qrScaner.presentQRScanner { value in
        if let value {
          // 处理扫描结果，可通过NotificationCenter发送通知
          NotificationCenter.default.post(
            name: .didReceiveScanResult,
            object: value)
        }
      }
    } else {
      selectedIndex = index
    }
  }
}

extension Notification.Name {
  static let didReceiveScanResult = Notification.Name("ScanResultNotification")
}
