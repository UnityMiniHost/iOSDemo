import UIKit

// MARK: - CustomTabBarDelegate

protocol CustomTabBarDelegate: AnyObject {
  func didSelectItem(at index: Int)
}

// MARK: - CustomTabBar

class CustomTabBar: UIView {

  // MARK: Lifecycle

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupUI()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupUI()
  }

  // MARK: Internal

  weak var delegate: CustomTabBarDelegate?


  func setupItems(_ items: [TabItem]) {
    self.items = items
    createButtons()
    setNeedsLayout()
  }

  func selectItem(at index: Int) {
    guard index < buttons.count else { return }

    UIView.animate(withDuration: 0.25) {
      for (btnIndex, btn) in self.buttons.enumerated() {
        let isSelected = btnIndex == index
        let imageView = btn.viewWithTag(100) as? UIImageView
        let titleLabel = btn.viewWithTag(101) as? UILabel

        imageView?.image = isSelected ? self.items[btnIndex].selectedImage : self.items[btnIndex].normalImage
        titleLabel?.textColor = isSelected ? UIColor(hexString: "#212121") : UIColor(hexString: "#666666")
      }
    }
  }

  // MARK: Private

  private var items: [TabItem] = []
  private var buttons: [UIButton] = []
  private let indicator = UIView()

  private func setupUI() {
    backgroundColor = .white
    addTopBorder()

    indicator.backgroundColor = UIColor(white: 0.9, alpha: 1.0)
    addSubview(indicator)

    let safeAreaBackground = UIView()
    safeAreaBackground.backgroundColor = .white
    addSubview(safeAreaBackground)
    safeAreaBackground.snp.makeConstraints {
      $0.top.equalTo(snp.bottom) // 正确关联到TabBar底部
      $0.leading.trailing.equalToSuperview()
      $0.bottom.equalToSuperview().priority(.low)
    }
  }

  private func addTopBorder() {
    let border = UIView()
    border.backgroundColor = UIColor(red: 0.9, green: 0.9, blue: 0.9, alpha: 1.0)
    addSubview(border)

    border.snp.makeConstraints {
      $0.top.leading.trailing.equalToSuperview()
      $0.height.equalTo(1.0/UIScreen.main.scale)
    }
  }

  private func createButtons() {
    for button in buttons { button.removeFromSuperview() }
    buttons.removeAll()

    for (index, item) in items.enumerated() {
      let button = UIButton()
      button.tag = index
      button.addTarget(self, action: #selector(didTapButton(_:)), for: .touchUpInside)

      let imageView = UIImageView(image: item.normalImage)
      imageView.contentMode = .scaleAspectFit
      imageView.tag = 100

      let titleLabel = UILabel()
      titleLabel.text = item.title
      titleLabel.font = UIFont.systemFont(ofSize: 10)
      titleLabel.textColor = UIColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1)
      titleLabel.tag = 101

      button.addSubview(imageView)
      button.addSubview(titleLabel)

      imageView.snp.makeConstraints {
        $0.centerX.equalToSuperview()
        $0.top.equalToSuperview().offset(6)
        $0.size.equalTo(CGSize(width: 24, height: 24))
      }

      titleLabel.snp.makeConstraints {
        $0.centerX.equalToSuperview()
        $0.top.equalTo(imageView.snp.bottom).offset(2)
      }

      addSubview(button)
      buttons.append(button)
    }

    var previousButton: UIButton?
    for button in buttons {
      button.snp.makeConstraints {
        $0.top.bottom.equalToSuperview()
        $0.width.equalToSuperview().dividedBy(buttons.count)

        if let previous = previousButton {
          $0.leading.equalTo(previous.snp.trailing)
        } else {
          $0.leading.equalToSuperview()
        }
      }
      previousButton = button
    }
  }

  @objc
  private func didTapButton(_ sender: UIButton) {
    // selectItem(at: sender.tag) // 禁用点击切换
    delegate?.didSelectItem(at: sender.tag)
  }
}

// MARK: - TabItem

struct TabItem {
  let title: String
  let normalImage: UIImage?
  let selectedImage: UIImage?
}
