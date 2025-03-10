import AVFoundation
import QRCodeReader
import UIKit

// MARK: - MainTabBarController

class MainTabBarController: UITabBarController {

  // MARK: Public

  public let customTabBar = CustomTabBar()

  // MARK: Internal

  lazy var readerVC: QRCodeReaderViewController = {
    let builder = QRCodeReaderViewControllerBuilder {
      $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)

      // Configure the view controller (optional)
      $0.showTorchButton = false
      $0.showSwitchCameraButton = false
      $0.showCancelButton = true
      $0.showOverlayView = true
      $0.rectOfInterest = CGRect(x: 0.2, y: 0.2, width: 0.6, height: 0.6)
    }

    return QRCodeReaderViewController(builder: builder)
  }()

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

  private func checkCameraPermission(completion: @escaping (Bool) -> Void) {
    let status = AVCaptureDevice.authorizationStatus(for: .video)

    switch status {
    case .authorized:
      completion(true)

    case .notDetermined:
      AVCaptureDevice.requestAccess(for: .video) { granted in
        DispatchQueue.main.async { completion(granted) }
      }

    default:
      completion(false)
    }
  }

  private func presentQRScanner() {
    checkCameraPermission { [weak self] granted in
      guard let self else { return }

      if granted {
        // Retrieve the QRCode content
        // By using the delegate pattern
        readerVC.delegate = self

        // Or by using the closure pattern
        readerVC.completionBlock = { (result: QRCodeReaderResult?) in
          print("scan result: \(result?.value ?? "")")
          if result != nil {
            // 处理扫描结果，可通过NotificationCenter发送通知
            NotificationCenter.default.post(
              name: .didReceiveScanResult,
              object: result?.value)
          }
        }

        // Presents the readerVC as modal form sheet
        readerVC.modalPresentationStyle = .formSheet

        present(readerVC, animated: true, completion: nil)
      } else {
        showPermissionAlert()
      }
    }
  }

  private func showPermissionAlert() {
    let alert = UIAlertController(
      title: "相机权限被禁用",
      message: "需要相机权限来扫描二维码",
      preferredStyle: .alert)

    alert.addAction(UIAlertAction(title: "取消", style: .cancel))
    alert.addAction(UIAlertAction(title: "去设置", style: .default) { _ in
      guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
      UIApplication.shared.open(url)
    })

    present(alert, animated: true)
  }
}

// MARK: CustomTabBarDelegate

extension MainTabBarController: CustomTabBarDelegate {
  func didSelectItem(at index: Int) {
    if index == 1 {
      presentQRScanner()
    } else {
      selectedIndex = index
    }
  }
}

// MARK: QRCodeReaderViewControllerDelegate

extension MainTabBarController: QRCodeReaderViewControllerDelegate {
  // QRCodeReaderViewControllerDelegate
  func reader(_ reader: QRCodeReaderViewController, didScanResult _: QRCodeReaderResult) {
    reader.stopScanning()
    dismiss(animated: true, completion: nil)
  }

  // This is an optional delegate method, that allows you to be notified when the user switches the cameraName
  // By pressing on the switch camera button
  func reader(_: QRCodeReaderViewController, didSwitchCamera newCaptureDevice: AVCaptureDeviceInput) {
    let cameraName = newCaptureDevice.device.localizedName
    if !cameraName.isEmpty {
      print("Switching capture to: \(cameraName)")
    } else {
      print("Failed to get camera name")
    }
  }

  func readerDidCancel(_ reader: QRCodeReaderViewController) {
    reader.stopScanning()
    dismiss(animated: true, completion: nil)
  }
}

extension Notification.Name {
  static let didReceiveScanResult = Notification.Name("ScanResultNotification")
}
