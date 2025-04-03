import UIKit
import webglhost_runtime

class GameView: UIView {

  // MARK: Lifecycle
  
  public var data: PlayedGameModel?

  // MARK: - Initialization
  init(game: PlayedGameModel) {
    super.init(frame: .zero)
    self.data = game
    setupViews()
    configure(with: game.iconUrl, title: game.name)
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  lazy var imageView: UIImageView = {
    let iv = UIImageView()
    iv.contentMode = .scaleAspectFill
    iv.clipsToBounds = true
    iv.layer.cornerRadius = 8.25
    return iv
  }()

  lazy var iconView: UIImageView = {
    let iv = UIImageView()
    iv.contentMode = .scaleAspectFit
    return iv
  }()

  lazy var titleLabel: UILabel = {
    let label = UILabel()
    label.font = UIFont.systemFont(ofSize: 10)
    label.textAlignment = .center
    label.numberOfLines = 1
    label.lineBreakMode = .byTruncatingTail
    return label
  }()


  func configure(with imageUrl: String, title: String) {
    imageView.sd_setImage(with: URL(string: imageUrl), placeholderImage: UIImage(named: "gameicon"))
    titleLabel.text = title
    iconView.image = UIImage(named: "flash")
  }

  // MARK: Private

  private lazy var iconContainer: UIView = {
    let view = UIView()
    view.backgroundColor = .clear
    view.layer.cornerRadius = 9
    view.layer.borderWidth = 0.75
    view.layer.borderColor = UIColor(hexString: "#EEEEEE").cgColor
    view.clipsToBounds = true
    return view
  }()

  private func setupViews() {
    iconContainer.addSubview(imageView)
    iconContainer.addSubview(iconView)
    addSubview(iconContainer)
    addSubview(titleLabel)

    imageView.snp.makeConstraints { make in
      make.top.centerX.equalToSuperview()
      make.width.height.equalTo(48)
    }

    iconView.snp.makeConstraints { make in
      make.bottom.equalTo(imageView)
      make.right.equalTo(imageView)
      make.width.equalTo(13.5)
      make.height.equalTo(16.5)
    }

    iconContainer.snp.makeConstraints { make in
      make.top.centerX.equalToSuperview()
      make.width.height.equalTo(48)
    }

    titleLabel.snp.makeConstraints { make in
      make.top.equalTo(imageView.snp.bottom).offset(4)
      make.centerX.equalToSuperview()
      make.width.equalTo(48)
      make.height.equalTo(16)
    }
  }
}
