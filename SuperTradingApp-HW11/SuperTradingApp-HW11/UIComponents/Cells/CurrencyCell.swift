import UIKit

// MARK: - Delegate Protocol

protocol CurrencyCellDelegate: AnyObject {
    func currencyCell(_ cell: CurrencyCell, didToggleFavorite currency: Currency)
}

// MARK: - CurrencyCell

final class CurrencyCell: UICollectionViewCell {

    static let reuseId = "CurrencyCell"

    weak var delegate: CurrencyCellDelegate?
    private var currency: Currency?

    private let codeLabel = UILabel()
    private let typeLabel = UILabel()
    private let starButton = UIButton(type: .system)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    // MARK: - Configure

    func configure(with currency: Currency, isDisabled: Bool, isFavorite: Bool) {
        self.currency = currency

        codeLabel.text = currency.code
        typeLabel.text = currency.type == .fiat ? "FIAT" : "CRYPTO"

        let starImage = isFavorite
            ? UIImage(systemName: "star.fill")
            : UIImage(systemName: "star")
        starButton.setImage(starImage, for: .normal)
        starButton.tintColor = isFavorite ? .systemYellow : .gray

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

    // MARK: - Action

    @objc private func starTapped() {
        guard let currency = currency else { return }
        delegate?.currencyCell(self, didToggleFavorite: currency)
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

        starButton.translatesAutoresizingMaskIntoConstraints = false
        starButton.addTarget(self, action: #selector(starTapped), for: .touchUpInside)

        contentView.addSubview(codeLabel)
        contentView.addSubview(typeLabel)
        contentView.addSubview(starButton)

        NSLayoutConstraint.activate([
            starButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: Layout.starTop),
            starButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -Layout.starTrailing),
            starButton.widthAnchor.constraint(equalToConstant: Layout.starSize),
            starButton.heightAnchor.constraint(equalToConstant: Layout.starSize),

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
        static let cornerRadius: CGFloat          = 10
        static let codeLabelCenterOffset: CGFloat = -8
        static let typeLabelTop: CGFloat          = 2
        static let starTop: CGFloat               = 4
        static let starTrailing: CGFloat          = 4
        static let starSize: CGFloat              = 16
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
