import UIKit

final class QuickCurrencyPickerViewController: UIViewController {

    var onPairChanged: ((Currency, Currency) -> Void)?
    var onFavoritesChanged: ((Set<String>) -> Void)?
    var onShowAllRequested: ((Currency, Currency, Set<String>) -> Void)?

    private let allCurrencies: [Currency]
    private var displayedCurrencies: [Currency] = []
    private var favoriteCodes: Set<String>

    private var firstCurrency: Currency
    private var secondCurrency: Currency
    private var editingSlot: Int? = 0

    private let firstCurrencyButton = UIButton(type: .system)
    private let arrowLabel = UILabel()
    private let secondCurrencyButton = UIButton(type: .system)
    private let subtitleLabel = UILabel()
    private var collectionView: UICollectionView!

    init(allCurrencies: [Currency], firstCurrency: Currency, secondCurrency: Currency, favoriteCodes: Set<String>) {
        self.allCurrencies = allCurrencies
        self.firstCurrency = firstCurrency
        self.secondCurrency = secondCurrency
        self.favoriteCodes = favoriteCodes
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = Messages.title
        view.backgroundColor = .black
        setupNavigationBar()
        setupPairSelector()
        setupSubtitle()
        setupCollectionView()
        makeConstraints()
        rebuildDisplayedCurrencies()
        refreshPairButtons()
    }
}

private extension QuickCurrencyPickerViewController {

    func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Все",
            style: .plain,
            target: self,
            action: #selector(showAllTapped)
        )
    }

    func setupPairSelector() {
        firstCurrencyButton.titleLabel?.font = .boldSystemFont(ofSize: Fonts.pairButtonSize)
        firstCurrencyButton.layer.cornerRadius = Layout.buttonCornerRadius
        firstCurrencyButton.layer.borderWidth = Layout.borderWidth
        firstCurrencyButton.translatesAutoresizingMaskIntoConstraints = false
        firstCurrencyButton.addTarget(self, action: #selector(firstCurrencyTapped), for: .touchUpInside)
        view.addSubview(firstCurrencyButton)

        arrowLabel.text = "->"
        arrowLabel.font = .boldSystemFont(ofSize: Fonts.pairButtonSize)
        arrowLabel.textColor = .gray
        arrowLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(arrowLabel)

        secondCurrencyButton.titleLabel?.font = .boldSystemFont(ofSize: Fonts.pairButtonSize)
        secondCurrencyButton.layer.cornerRadius = Layout.buttonCornerRadius
        secondCurrencyButton.layer.borderWidth = Layout.borderWidth
        secondCurrencyButton.translatesAutoresizingMaskIntoConstraints = false
        secondCurrencyButton.addTarget(self, action: #selector(secondCurrencyTapped), for: .touchUpInside)
        view.addSubview(secondCurrencyButton)
    }

    func setupSubtitle() {
        subtitleLabel.text = Messages.subtitle
        subtitleLabel.textColor = .lightGray
        subtitleLabel.font = .systemFont(ofSize: Fonts.subtitleSize)
        subtitleLabel.numberOfLines = 0
        subtitleLabel.textAlignment = .center
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(subtitleLabel)
    }

    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = Layout.itemSpacing
        layout.minimumLineSpacing = Layout.itemSpacing
        layout.sectionInset = UIEdgeInsets(top: Layout.sectionInset, left: 0, bottom: Layout.sectionInset, right: 0)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor(white: 0.10, alpha: 1)
        collectionView.layer.cornerRadius = Layout.containerCornerRadius
        collectionView.register(CurrencyCell.self, forCellWithReuseIdentifier: CurrencyCell.reuseId)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
    }

    func makeConstraints() {
        let safe = view.safeAreaLayoutGuide

        NSLayoutConstraint.activate([
            firstCurrencyButton.topAnchor.constraint(equalTo: safe.topAnchor, constant: Layout.sidePadding),
            firstCurrencyButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            firstCurrencyButton.heightAnchor.constraint(equalToConstant: Layout.pairButtonHeight),
            firstCurrencyButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: Layout.pairButtonWidthMultiplier),

            arrowLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            arrowLabel.centerYAnchor.constraint(equalTo: firstCurrencyButton.centerYAnchor),

            secondCurrencyButton.topAnchor.constraint(equalTo: safe.topAnchor, constant: Layout.sidePadding),
            secondCurrencyButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),
            secondCurrencyButton.heightAnchor.constraint(equalToConstant: Layout.pairButtonHeight),
            secondCurrencyButton.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: Layout.pairButtonWidthMultiplier),

            subtitleLabel.topAnchor.constraint(equalTo: firstCurrencyButton.bottomAnchor, constant: Layout.elementSpacing),
            subtitleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            subtitleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),

            collectionView.topAnchor.constraint(equalTo: subtitleLabel.bottomAnchor, constant: Layout.elementSpacing),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),
            collectionView.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -Layout.sidePadding)
        ])
    }
}

private extension QuickCurrencyPickerViewController {

    @objc func closeTapped() {
        dismiss(animated: true)
    }

    @objc func showAllTapped() {
        onShowAllRequested?(firstCurrency, secondCurrency, favoriteCodes)
    }

    @objc func firstCurrencyTapped() {
        editingSlot = editingSlot == 0 ? nil : 0
        refreshPairButtons()
        collectionView.reloadData()
    }

    @objc func secondCurrencyTapped() {
        editingSlot = editingSlot == 1 ? nil : 1
        refreshPairButtons()
        collectionView.reloadData()
    }

    func rebuildDisplayedCurrencies() {
        let favoriteCurrencies = allCurrencies.filter { favoriteCodes.contains($0.code) }
        let popularCurrencies = CurrencyDataProvider.popularCurrencyCodes.compactMap { code in
            allCurrencies.first(where: { $0.code == code })
        }

        var reducedCurrencies = favoriteCurrencies
        for currency in popularCurrencies where !reducedCurrencies.contains(currency) {
            reducedCurrencies.append(currency)
        }

        displayedCurrencies = Array(reducedCurrencies.prefix(10))
        collectionView.reloadData()
    }

    func selectCurrency(_ currency: Currency) {
        guard let slot = editingSlot else { return }

        if slot == 0 {
            guard currency != secondCurrency else { return }
            firstCurrency = currency
        } else {
            guard currency != firstCurrency else { return }
            secondCurrency = currency
        }

        onPairChanged?(firstCurrency, secondCurrency)
        refreshPairButtons()
        collectionView.reloadData()
    }

    func refreshPairButtons() {
        firstCurrencyButton.setTitle(firstCurrency.code, for: .normal)
        secondCurrencyButton.setTitle(secondCurrency.code, for: .normal)

        if editingSlot == 0 {
            firstCurrencyButton.setTitleColor(.systemGreen, for: .normal)
            firstCurrencyButton.layer.borderColor = UIColor.systemGreen.cgColor
            secondCurrencyButton.setTitleColor(.white, for: .normal)
            secondCurrencyButton.layer.borderColor = UIColor.clear.cgColor
        } else if editingSlot == 1 {
            firstCurrencyButton.setTitleColor(.white, for: .normal)
            firstCurrencyButton.layer.borderColor = UIColor.clear.cgColor
            secondCurrencyButton.setTitleColor(.systemGreen, for: .normal)
            secondCurrencyButton.layer.borderColor = UIColor.systemGreen.cgColor
        } else {
            firstCurrencyButton.setTitleColor(.white, for: .normal)
            firstCurrencyButton.layer.borderColor = UIColor.clear.cgColor
            secondCurrencyButton.setTitleColor(.white, for: .normal)
            secondCurrencyButton.layer.borderColor = UIColor.clear.cgColor
        }
    }
}

extension QuickCurrencyPickerViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        displayedCurrencies.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CurrencyCell.reuseId, for: indexPath) as! CurrencyCell
        let currency = displayedCurrencies[indexPath.item]

        let isDisabled: Bool
        if editingSlot == 0 {
            isDisabled = currency == secondCurrency
        } else if editingSlot == 1 {
            isDisabled = currency == firstCurrency
        } else {
            isDisabled = false
        }

        cell.delegate = self
        cell.configure(with: currency, isDisabled: isDisabled, isFavorite: favoriteCodes.contains(currency.code))
        return cell
    }
}

extension QuickCurrencyPickerViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let currency = displayedCurrencies[indexPath.item]

        let isDisabled: Bool
        if editingSlot == 0 {
            isDisabled = currency == secondCurrency
        } else if editingSlot == 1 {
            isDisabled = currency == firstCurrency
        } else {
            isDisabled = false
        }

        guard !isDisabled else { return }

        if let cell = collectionView.cellForItem(at: indexPath) as? CurrencyCell {
            cell.playSelectionAnimation { [weak self] in
                self?.selectCurrency(currency)
            }
        } else {
            selectCurrency(currency)
        }
    }
}

extension QuickCurrencyPickerViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing = Layout.itemSpacing * (Layout.columnCount - 1)
        let width = (collectionView.bounds.width - totalSpacing - Layout.sectionPadding) / Layout.columnCount
        return CGSize(width: width, height: Layout.cellHeight)
    }
}

extension QuickCurrencyPickerViewController: CurrencyCellDelegate {

    func currencyCell(_ cell: CurrencyCell, didToggleFavorite currency: Currency) {
        if favoriteCodes.contains(currency.code) {
            favoriteCodes.remove(currency.code)
        } else {
            favoriteCodes.insert(currency.code)
        }

        onFavoritesChanged?(favoriteCodes)
        rebuildDisplayedCurrencies()
    }
}

private extension QuickCurrencyPickerViewController {

    enum Messages {
        static let title = "Быстрый выбор"
        static let subtitle = "Сначала показываются избранные валюты. Если их мало, список дополняется популярными."
    }

    enum Layout {
        static let sidePadding: CGFloat = 16
        static let elementSpacing: CGFloat = 12
        static let pairButtonHeight: CGFloat = 48
        static let pairButtonWidthMultiplier: CGFloat = 0.38
        static let buttonCornerRadius: CGFloat = 10
        static let containerCornerRadius: CGFloat = 14
        static let borderWidth: CGFloat = 2
        static let itemSpacing: CGFloat = 8
        static let sectionInset: CGFloat = 8
        static let sectionPadding: CGFloat = 16
        static let columnCount: CGFloat = 3
        static let cellHeight: CGFloat = 56
    }

    enum Fonts {
        static let pairButtonSize: CGFloat = 22
        static let subtitleSize: CGFloat = 13
    }
}
