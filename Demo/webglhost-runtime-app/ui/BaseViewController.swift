import UIKit

// MARK: - BaseViewController

class BaseViewController: UIViewController {

  // MARK: Public

  public func restoreTabBarIfNeeded(animated: Bool) {
    guard hidesCustomTabBar else { return }
    guard let tabBar = getCustomTabBar() else { return }

    let restoreBlock = {
      tabBar.alpha = 1
      tabBar.isHidden = false
    }

    animated ? UIView.animate(withDuration: 0.25, animations: restoreBlock) : restoreBlock()
  }

  // MARK: Internal

  var hidesCustomTabBar = false {
    didSet {
      updateTabBarVisibility(animated: false)
    }
  }


  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    updateTabBarVisibility(animated: animated)
  }

  override func viewWillDisappear(_ animated: Bool) {
    super.viewWillDisappear(animated)
    restoreTabBarIfNeeded(animated: animated)
  }

  // MARK: Private

  private func updateTabBarVisibility(animated: Bool) {
    guard let tabBar = getCustomTabBar() else { return }

    let updateBlock = {
      tabBar.alpha = self.hidesCustomTabBar ? 0 : 1
      tabBar.isHidden = self.hidesCustomTabBar
    }

    animated ? UIView.animate(withDuration: 0.25, animations: updateBlock) : updateBlock()
  }

  private func getCustomTabBar() -> UIView? {
    (tabBarController as? MainTabBarController)?.customTabBar
  }
}

// MARK: UINavigationControllerDelegate

extension BaseViewController: UINavigationControllerDelegate {
  func navigationController(
    _ navigationController: UINavigationController,
    willShow viewController: UIViewController,
    animated _: Bool)
  {
    guard
      let fromVC = navigationController.transitionCoordinator?.viewController(forKey: .from),
      !navigationController.viewControllers.contains(fromVC)
    else {
      return
    }

    if let showingVC = viewController as? BaseViewController {
      UIView.animate(withDuration: 0.25) {
        self.getCustomTabBar()?.alpha = showingVC.hidesCustomTabBar ? 0 : 1
      }
    }
  }
}
