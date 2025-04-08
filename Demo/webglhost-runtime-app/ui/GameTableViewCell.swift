import UIKit
import webglhost_runtime

class GameTableViewCell: UITableViewCell {

  // MARK: Lifecycle

  override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setupViews()
  }

  required init?(coder _: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  // MARK: Internal

  static let reuseIdentifier = "GameCell"

  override func prepareForReuse() {
    super.prepareForReuse()
    for arrangedSubview in tagsStack.arrangedSubviews { arrangedSubview.removeFromSuperview() }
  }

  func configure(with game: GameModel) {
    gameImageView.sd_setImage(with: URL(string: game.iconUrl!), placeholderImage: UIImage(named: "gameicon"))
    titleLabel.text = game.name
    descriptionLabel.text = game.briefIntro
    updateTags(tags: game.tags!)
  }
  
  func configure(recentlyPlayedGame game: PlayedGameModel) {
    gameImageView.sd_setImage(with: URL(string: game.iconUrl), placeholderImage: UIImage(named: "gameicon"))
    titleLabel.text = game.name
    descriptionLabel.text = game.briefIntro
    updateTags(tags: game.tags)
  }

  // MARK: Private

  private lazy var iconContainer: UIView = {
    let view = UIView()
    view.backgroundColor = .clear
    view.layer.cornerRadius = 12
    view.layer.borderWidth = 1
    view.layer.borderColor = UIColor(hexString: "#EEEEEE").cgColor
    view.clipsToBounds = true
    return view
  }()

  private lazy var gameImageView: UIImageView = {
    let iv = UIImageView()
    iv.contentMode = .scaleAspectFill
    iv.clipsToBounds = true
    iv.layer.cornerRadius = 11
    return iv
  }()

  private lazy var iconView: UIImageView = {
    let iv = UIImageView()
    iv.image = UIImage(named: "flash")
    iv.contentMode = .scaleAspectFit
    return iv
  }()

  private lazy var tagsStack: UIStackView = {
    let stack = UIStackView()
    stack.axis = .horizontal
    stack.spacing = 4
    stack.alignment = .leading
    return stack
  }()

  private lazy var titleLabel = UILabel()
  private lazy var descriptionLabel = UILabel()

  private lazy var playButton: UIButton = {
    let btn = UIButton()
    btn.setTitle("打开", for: .normal)
    btn.setTitleColor(UIColor(hexString: "#2196F3"), for: .normal)
    btn.titleLabel?.font = UIFont.systemFont(ofSize: 14, weight: .regular)
    btn.backgroundColor = UIColor(hexString: "#E9F4FE")
    btn.isEnabled = false
    return btn
  }()


  private func setupViews() {
    selectionStyle = .none

    let container = UIStackView()
    container.axis = .horizontal
    container.spacing = 12
    container.alignment = .center
    contentView.addSubview(container)

    iconContainer.addSubview(gameImageView)
    iconContainer.addSubview(iconView)

    gameImageView.snp.makeConstraints {
      $0.edges.equalToSuperview()
      $0.size.equalTo(64)
    }

    iconView.snp.makeConstraints { make in
      make.bottom.equalTo(gameImageView)
      make.right.equalTo(gameImageView)
      make.width.equalTo(18)
      make.height.equalTo(22)
    }

    let middleStack = UIStackView()
    middleStack.axis = .vertical
    middleStack.spacing = 8
    middleStack.alignment = .leading


    titleLabel.font = UIFont.systemFont(ofSize: 14, weight: .medium)
    descriptionLabel.font = UIFont.systemFont(ofSize: 12)
    descriptionLabel.textColor = .gray
    descriptionLabel.numberOfLines = 1

    // 组装中部
    middleStack.addArrangedSubview(titleLabel)
    middleStack.addArrangedSubview(tagsStack)
    middleStack.addArrangedSubview(descriptionLabel)

    // 后部按钮
    playButton.layer.cornerRadius = 14
    playButton.snp.makeConstraints {
      $0.width.equalTo(60)
      $0.height.equalTo(28)
    }

    container.addArrangedSubview(iconContainer)
    container.addArrangedSubview(middleStack)
    container.addArrangedSubview(playButton)

    container.snp.makeConstraints {
      $0.edges.equalToSuperview().inset(UIEdgeInsets(top: 12, left: 16, bottom: 12, right: 16))
    }

    middleStack.setContentHuggingPriority(.defaultLow, for: .horizontal)
    playButton.setContentHuggingPriority(.required, for: .horizontal)
  }

  private func updateTags(tags: [String]) {
    for arrangedSubview in tagsStack.arrangedSubviews { arrangedSubview.removeFromSuperview() }

    let maxTags = 3
    for tag in tags.prefix(maxTags) {
      let label = createTagLabel(text: tag)
      tagsStack.addArrangedSubview(label)
    }

    if tags.count > maxTags {
      let moreLabel = createTagLabel(text: "+\(tags.count - maxTags)")
      tagsStack.addArrangedSubview(moreLabel)
    }
  }

  private func createTagLabel(text: String) -> UIView {
    let container = UIView()
    container.backgroundColor = UIColor(white: 0.95, alpha: 1)
    container.layer.cornerRadius = 9
    container.clipsToBounds = true

    let label = UILabel()
    label.text = text
    label.font = UIFont.systemFont(ofSize: 10)
    label.textColor = .darkGray
    label.textAlignment = .center

    container.addSubview(label)

    label.snp.makeConstraints {
      $0.leading.trailing.equalToSuperview().inset(8)
      $0.top.bottom.equalToSuperview().inset(2)
    }

    return container
  }
}
