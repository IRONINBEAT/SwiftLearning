import UIKit

// MARK: - Delegate Protocol

protocol FavoritesFilterViewDelegate: AnyObject {
    func favoritesFilterView(_ view: FavoritesFilterView, didChange isOn: Bool)
}

// MARK: - FavoritesFilterView

final class FavoritesFilterView: UIView {

    weak var delegate: FavoritesFilterViewDelegate?

    private let titleLabel = UILabel()
    private let toggle     = UISwitch()

    var isOn: Bool {
        return toggle.isOn
    }

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Action

    @objc private func toggleChanged() {
        delegate?.favoritesFilterView(self, didChange: toggle.isOn)
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = UIColor(white: Layout.backgroundWhite, alpha: 1)
        layer.cornerRadius = Layout.cornerRadius

        titleLabel.text      = Strings.title
        titleLabel.font      = .systemFont(ofSize: Fonts.title)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        toggle.onTintColor = .systemYellow
        toggle.translatesAutoresizingMaskIntoConstraints = false
        toggle.addTarget(self, action: #selector(toggleChanged), for: .valueChanged)

        addSubview(titleLabel)
        addSubview(toggle)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Layout.padding),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor),

            toggle.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Layout.padding),
            toggle.centerYAnchor.constraint(equalTo: centerYAnchor),

            heightAnchor.constraint(equalToConstant: Layout.viewHeight)
        ])
    }
}

// MARK: - Constants

private extension FavoritesFilterView {

    enum Strings {
        static let title = "☆ Избранное"
    }

    enum Layout {
        static let padding: CGFloat          = 12
        static let cornerRadius: CGFloat     = 12
        static let viewHeight: CGFloat       = 44
        static let backgroundWhite: CGFloat  = 0.12
    }

    enum Fonts {
        static let title: CGFloat = 15
    }
}
