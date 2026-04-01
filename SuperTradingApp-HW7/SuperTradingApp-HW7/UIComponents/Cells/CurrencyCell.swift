import UIKit

final class CurrencyCell: UICollectionViewCell {

    static let reuseId = "CurrencyCell"

    private let codeLabel = UILabel()
    private let typeLabel = UILabel()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(with currency: Currency, isDisabled: Bool) {
        codeLabel.text = currency.code
        typeLabel.text = currency.type == .fiat ? "FIAT" : "CRYPTO"

        if isDisabled {
            contentView.backgroundColor = UIColor(white: Appearance.disabledBackground, alpha: 1)
            codeLabel.textColor = .darkGray
            typeLabel.textColor = .darkGray
        } else {
            contentView.backgroundColor = UIColor(white: Appearance.enabledBackground, alpha: 1)
            codeLabel.textColor = .white
            typeLabel.textColor = currency.type == .fiat ? .systemYellow : .systemCyan
        }
    }

    // MARK: - UI Setup

    private func setupUI() {
        contentView.layer.cornerRadius = Layout.cornerRadius
        contentView.clipsToBounds = true

        codeLabel.font = .boldSystemFont(ofSize: Fonts.codeLabel)
        codeLabel.textAlignment = .center
        codeLabel.translatesAutoresizingMaskIntoConstraints = false

        typeLabel.font = .systemFont(ofSize: Fonts.typeLabel)
        typeLabel.textAlignment = .center
        typeLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(codeLabel)
        contentView.addSubview(typeLabel)

        NSLayoutConstraint.activate([
            codeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            codeLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor, constant: Layout.codeLabelCenterOffset),

            typeLabel.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            typeLabel.topAnchor.constraint(equalTo: codeLabel.bottomAnchor, constant: Layout.typeLabelTop)
        ])
    }
}

// MARK: - Constants

private extension CurrencyCell {

    enum Layout {
        static let cornerRadius: CGFloat       = 10
        static let codeLabelCenterOffset: CGFloat = -8
        static let typeLabelTop: CGFloat       = 2
    }

    enum Fonts {
        static let codeLabel: CGFloat = 14
        static let typeLabel: CGFloat = 10
    }

    enum Appearance {
        static let disabledBackground: CGFloat = 0.15
        static let enabledBackground: CGFloat  = 0.2
    }
}
