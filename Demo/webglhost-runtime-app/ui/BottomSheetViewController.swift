import UIKit

// MARK: - BottomSheetViewController

class BottomSheetViewController: UIViewController {

  // MARK: Internal

  var backgroundColor: UIColor {
    isDarkMode ? darkModeBackgroundColor : lightModeBackgroundColor
  }

  var textColor: UIColor {
    isDarkMode ? darkModeTextColor : lightModeTextColor
  }

  var contentColor: UIColor {
    isDarkMode ? darkModeContentColor : lightModeContentColor
  }

  // MARK: - View Setup

  override func viewDidLoad() {
    super.viewDidLoad()
    setupViews()
    setupGestures()
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    animatePresent()
  }

  @objc
  func dismissBottomSheetWithAnimate() {
    UIView.animate(withDuration: 0.2, animations: { [weak self] in
      guard let self else { return }
      dimmedView.alpha = maxDimmedAlpha
      mainContainerView.frame.origin.y = view.frame.height
    }, completion: { [weak self] _ in
      self?.dismiss(animated: false)
    })
  }

  func dismissBottomSheet(animated _: Bool, completion: (() -> Void)? = nil) {
    dismiss(animated: false, completion: completion)
  }

  // sub-view controller will call this function to set content
  func setContent(content: UIView) {
    contentView.addSubview(content)
    content.snp.makeConstraints { make in
      make.edges.equalTo(contentView)
    }
    view.layoutIfNeeded()
  }

  func setMenuStyle(style: String) {
    if style == "dark" {
      isDarkMode = true
    } else {
      isDarkMode = false
    }
  }

  func setTitleView(titleView: UIView) {
    topBarView.addSubview(titleView)
    titleView.snp.makeConstraints { make in
      make.edges.equalTo(topBarView)
    }
    view.layoutIfNeeded()
  }

  // MARK: Private

  // MARK: - UI

  private lazy var mainContainerView: UIView = {
    let view = UIView()
    view.backgroundColor = self.backgroundColor
    view.layer.cornerRadius = 24
    view.clipsToBounds = true
    return view
  }()

  private lazy var contentView: UIView = {
    let view = UIView()
    return view
  }()

  private lazy var topBarView: UIView = {
    let view = UIView()
    view.backgroundColor = self.contentColor
    return view
  }()

  private lazy var bottomdivider: UIView = {
    let view = UIView()
    view.backgroundColor = UIColor(hexString: "#3D3D3D")
    return view
  }()

  private lazy var dismissButton: UIButton = {
    let button = UIButton()
    button.setTitle("取消", for: .normal)
    button.setTitleColor(UIColor(hexString: "#5D7E96"), for: .normal)
    button.addTarget(self, action: #selector(dismissBottomSheetWithAnimate), for: .touchUpInside)
    return button
  }()

  private lazy var dimmedView: UIView = {
    let view = UIView()
    view.backgroundColor = .black
    view.alpha = 0
    return view
  }()

  /// Maximum alpha for dimmed view
  private let maxDimmedAlpha: CGFloat = 0.2
  /// Minimum drag vertically that enable bottom sheet to dismiss
  private let minDismissiblePanHeight: CGFloat = 20
  /// Minimum spacing between the top edge and bottom sheet
  private var minTopSpacing: CGFloat = 10

  /// Menu style: is dark mode or not
  private var isDarkMode = true
  private let lightModeBackgroundColor = UIColor(hexString: "#e3e3e3")
  private let lightModeTextColor = UIColor.black
  private let lightModeContentColor = UIColor.white
  private let darkModeBackgroundColor = UIColor(hexString: "#313132")
  private let darkModeTextColor = UIColor.white
  private let darkModeContentColor = UIColor.lightGray.withAlphaComponent(0.1)

  private func setupViews() {
    view.backgroundColor = .clear
    view.addSubview(dimmedView)
    dimmedView.snp.makeConstraints { make in
      make.edges.equalTo(view)
    }

    // Container View
    view.addSubview(mainContainerView)
    mainContainerView.snp.makeConstraints { make in
      make.left.equalTo(view).offset(12)
      make.right.bottom.equalTo(view).offset(-12)
      make.top.greaterThanOrEqualTo(view).offset(minTopSpacing)
    }

    // Top draggable bar view
    mainContainerView.addSubview(topBarView)
    topBarView.snp.makeConstraints { make in
      make.top.left.right.equalTo(mainContainerView)
      make.height.equalTo(56)
    }

    // DismissButton
    mainContainerView.addSubview(dismissButton)
    dismissButton.snp.makeConstraints { make in
      make.left.bottom.right.equalTo(mainContainerView)
      make.height.equalTo(60)
    }

    dismissButton.addSubview(bottomdivider)
    bottomdivider.snp.makeConstraints { make in
      make.left.top.right.equalTo(dismissButton)
      make.height.equalTo(1)
    }

    // Content View
    mainContainerView.addSubview(contentView)
    contentView.snp.makeConstraints { make in
      make.left.equalTo(mainContainerView).offset(12)
      make.right.equalTo(mainContainerView).offset(-12)
      make.top.equalTo(topBarView.snp.bottom).offset(12)
      make.bottom.equalTo(dismissButton.snp.top).offset(-12)
    }
  }

  private func setupGestures() {
    let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapDimmedView))
    dimmedView.addGestureRecognizer(tapGesture)

    let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
    panGesture.delaysTouchesBegan = false
    panGesture.delaysTouchesEnded = false
    topBarView.addGestureRecognizer(panGesture)
  }

  @objc
  private func handleTapDimmedView() {
    dismissBottomSheetWithAnimate()
  }

  @objc
  private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
    let translation = gesture.translation(in: view)
    // get drag direction
    let isDraggingDown = translation.y > 0
    guard isDraggingDown else { return }

    let pannedHeight = translation.y
    let currentY = view.frame.height - mainContainerView.frame.height
    // handle gesture state
    switch gesture.state {
    case .changed:
      // This state will occur when user is dragging
      mainContainerView.frame.origin.y = currentY + pannedHeight

    case .ended:
      // When user stop dragging
      // if fulfil the condition dismiss it, else move to original position
      if pannedHeight >= minDismissiblePanHeight {
        dismissBottomSheetWithAnimate()
      } else {
        mainContainerView.frame.origin.y = currentY
      }

    default:
      break
    }
  }

  private func animatePresent() {
    dimmedView.alpha = 0
    mainContainerView.transform = CGAffineTransform(translationX: 0, y: view.frame.height)
    UIView.animate(withDuration: 0.2) { [weak self] in
      self?.mainContainerView.transform = .identity
    }
    // add more animation duration for smoothness
    UIView.animate(withDuration: 0.4) { [weak self] in
      guard let self else { return }
      dimmedView.alpha = maxDimmedAlpha
    }
  }
}

extension UIViewController {
  func presentBottomSheet(viewController: BottomSheetViewController) {
    viewController.modalPresentationStyle = .overFullScreen
    present(viewController, animated: false, completion: nil)
  }
}
