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

    // Overlay view used for the animated green highlight on selection
    private let selectionOverlay: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.35)
        v.alpha = 0
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

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

        // Reset overlay
        selectionOverlay.alpha = 0
        transform = .identity
    }

    // MARK: - Selection Animation
    //
    // Call this from the collection view's didSelectItemAt BEFORE calling
    // the existing selectCurrency logic, so the animation plays on tap.
    //
    // In QuickCurrencyPickerViewController, replace:
    //   func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    //       selectCurrency(displayedCurrencies[indexPath.item])
    //   }
    // with:
    //   func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    //       if let cell = collectionView.cellForItem(at: indexPath) as? CurrencyCell {
    //           cell.playSelectionAnimation { [weak self] in
    //               self?.selectCurrency(self!.displayedCurrencies[indexPath.item])
    //           }
    //       } else {
    //           selectCurrency(displayedCurrencies[indexPath.item])
    //       }
    //   }

    func playSelectionAnimation(completion: (() -> Void)? = nil) {
        // Animation 1: Scale down (compress) then bounce back
        UIView.animate(
            withDuration: 0.12,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                self.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
            },
            completion: { _ in
                UIView.animate(
                    withDuration: 0.18,
                    delay: 0,
                    usingSpringWithDamping: 0.5,
                    initialSpringVelocity: 6,
                    options: .curveEaseOut,
                    animations: {
                        self.transform = .identity
                    },
                    completion: { _ in
                        completion?()
                    }
                )
            }
        )

        // Animation 2: Green background overlay fade in then fade out
        UIView.animate(
            withDuration: 0.15,
            delay: 0,
            options: .curveEaseIn,
            animations: {
                self.selectionOverlay.alpha = 1
            },
            completion: { _ in
                UIView.animate(
                    withDuration: 0.35,
                    delay: 0.1,
                    options: .curveEaseOut,
                    animations: {
                        self.selectionOverlay.alpha = 0
                    }
                )
            }
        )
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

        // Selection overlay (must be added before other subviews so it sits beneath labels)
        contentView.addSubview(selectionOverlay)
        NSLayoutConstraint.activate([
            selectionOverlay.topAnchor.constraint(equalTo: contentView.topAnchor),
            selectionOverlay.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            selectionOverlay.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            selectionOverlay.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ])

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
