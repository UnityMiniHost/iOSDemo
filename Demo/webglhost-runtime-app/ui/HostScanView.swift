import AVFoundation
import QRCodeReader
import SnapKit
import UIKit
import webglhost_runtime

// MARK: - QRScanner

class QRScanner {

  // MARK: Lifecycle

  init(view: UIViewController) {
    self.view = view
  }

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

  func presentQRScanner(completion: @escaping (String?) -> Void) {
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
            completion(result?.value)
          }
        }

        // Presents the readerVC as modal form sheet
        readerVC.modalPresentationStyle = .formSheet

        view.present(readerVC, animated: true, completion: nil)
      } else {
        showPermissionAlert()
      }
    }
  }

  // MARK: Private

  private let view: UIViewController

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

    view.present(alert, animated: true)
  }
}


// MARK: QRCodeReaderViewControllerDelegate

extension QRScanner: QRCodeReaderViewControllerDelegate {
  // QRCodeReaderViewControllerDelegate
  func reader(_ reader: QRCodeReaderViewController, didScanResult _: QRCodeReaderResult) {
    reader.stopScanning()
    view.dismiss(animated: true, completion: nil)
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
    view.dismiss(animated: true, completion: nil)
  }
}

// MARK: - HostScanUIView

class HostScanUIView: UIView {

  // MARK: Lifecycle

  // MARK: - Initialization
  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
    setupConstraints()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
    setupConstraints()
  }

  // MARK: Internal

  lazy var qrScanner: QRScanner? = {
    if let view = getOwningViewController() {
      return QRScanner(view: view)
    }

    TJLogger.debug("[\(Config.APP_LOG_TAG)] init scanner failed.")
    return nil
  }()

  let stackView = UIStackView()

  @objc
  func settingButtonTap() {
    if let view = getOwningViewController() {
      let alert = UIAlertController(
        title: "\(Config.HOST_ORG_NAME)",
        message: nil,
        preferredStyle: .alert)

      alert.addAction(UIAlertAction(title: "确定", style: .cancel))

      let paragraphStyle = NSMutableParagraphStyle()
      paragraphStyle.alignment = .left

      let message = """

            Host Domain:
            \(Config.HOST_SERVER_API_BASE)

            App ID:
            \(Config.APP_ID)

            Runtime SDK Version:
            \(TJHostHandle.getVersionName())(\(String(describing: TJHostHandle.getVersionCode())))
        """
      let attributedMessage = NSMutableAttributedString(string: message, attributes: [
        NSAttributedString.Key.paragraphStyle: paragraphStyle,
        NSAttributedString.Key.font: UIFont.systemFont(ofSize: 14),
      ])

      alert.setValue(attributedMessage, forKey: "attributedMessage")

      view.present(alert, animated: true)
    }
  }

  @objc
  func scanButtonTap() {
    qrScanner?.presentQRScanner { value in
      guard let value else {
        TJLogger.debug("[\(Config.APP_LOG_TAG)] scan result failed.")
        return
      }

      do {
        let hostModel = try JSONDecoder().decode(HostModel.self, from: Data(value.utf8))
        Config.setHostConfig(hostModel)
        NotificationCenter.default.post(
          name: .didUpdateHostConfig,
          object: hostModel)

        self.settingButtonTap()

      } catch {
        TJLogger.error("[\(Config.APP_LOG_TAG)] Decode json error: \(error.localizedDescription)")
      }
    }
  }

  // MARK: Private

  private lazy var frameworkBundle = Bundle(for: type(of: self))

  private lazy var settingButton: UIButton = {
    let settingButton = UIButton(type: .system)
    settingButton.setImage(UIImage(named: "settings", in: frameworkBundle, compatibleWith: nil), for: .normal)
    settingButton.imageEdgeInsets = UIEdgeInsets(top: 2, left: 2, bottom: 2, right: 2)
    settingButton.tintColor = .white
    settingButton.addTarget(self, action: #selector(settingButtonTap), for: .touchUpInside)
    settingButton.isUserInteractionEnabled = true
    return settingButton
  }()

  private lazy var scanButton: UIButton = {
    let scanButton = UIButton(type: .system)
    scanButton.setImage(UIImage(named: "qrscan-fill", in: frameworkBundle, compatibleWith: nil), for: .normal)
    scanButton.tintColor = .white
    scanButton.addTarget(self, action: #selector(scanButtonTap), for: .touchUpInside)
    scanButton.isUserInteractionEnabled = true
    return scanButton
  }()

  private func setupUI() {
    clipsToBounds = true

    stackView.axis = .vertical
    stackView.spacing = 8
    stackView.distribution = .fill

    stackView.addArrangedSubview(settingButton)
    stackView.addArrangedSubview(scanButton)

    addSubview(stackView)
  }

  private func setupConstraints() {
    stackView.snp.makeConstraints { make in
      make.width.equalToSuperview()
      make.height.equalToSuperview()
    }

    settingButton.snp.makeConstraints { make in
      make.width.equalTo(20)
      make.height.equalTo(20)
    }

    scanButton.snp.makeConstraints { make in
      make.width.equalTo(20)
      make.height.equalTo(20)
    }
  }

}

extension UIResponder {
  func getOwningViewController() -> UIViewController? {
    var nextResponder = self
    while let next = nextResponder.next {
      nextResponder = next
      if let viewController = nextResponder as? UIViewController {
        return viewController
      }
    }
    return nil
  }
}
