import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  var window: UIWindow?
  var orientationMask: UIInterfaceOrientationMask = .portrait

  func application(_: UIApplication, didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
    window = UIWindow()
    window?.rootViewController = MainTabBarController()
    window?.makeKeyAndVisible()

    return true
  }

  func application(_: UIApplication, supportedInterfaceOrientationsFor _: UIWindow?) -> UIInterfaceOrientationMask {
    orientationMask
  }

  func applicationDidEnterBackground(_: UIApplication) { }

  func applicationWillEnterForeground(_: UIApplication) { }
  
  func applicationWillTerminate(_ application: UIApplication) {
  }
}
