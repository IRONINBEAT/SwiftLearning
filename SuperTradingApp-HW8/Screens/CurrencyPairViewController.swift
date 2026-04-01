import UIKit

final class CurrencyPairViewController: UIViewController {

    // MARK: - Data

    private var allCurrencies: [Currency]       = []
    private var displayedCurrencies: [Currency] = []
    private var favoriteCodes: Set<String>       = []
    private var isFavoritesFilterOn              = false

    private var firstCurrency: Currency!
    private var secondCurrency: Currency!
    private var exchangeRate: Double = 0

    private var editingSlot: Int? = nil

    private enum CurrencyTypeFilter { case all, fiat, crypto }
    private var currentTypeFilter: CurrencyTypeFilter = .all

    private var timer: Timer?
    private var secondsLeft      = 5
    private let timerTotalSeconds = 5


    // MARK: - UI Elements

    private let firstCurrencyButton  = UIButton(type: .system)
    private let arrowLabel           = UILabel()
    private let secondCurrencyButton = UIButton(type: .system)
    private let rateLabel            = UILabel()

    private let favoritesFilterView  = FavoritesFilterView()
    private let filterSegment        = UISegmentedControl(items: ["Все", "Фиат", "Крипта"])

    private let converterContainer   = UIView()
    private let amountTextField      = UITextField()
    private let resultLabel          = UILabel()
    private let timerLabel           = UILabel()

    private var collectionView: UICollectionView!
    private let emptyStateLabel      = UILabel()


    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        title = MessagesToUser.title

        loadCurrencies()
        setupPairSelector()
        setupFavoritesFilter()
        setupFilterSegment()
        setupConverter()
        setupCollectionView()
        setupEmptyState()
        makeConstraints()

        applyFilters()
        updateRateAndConverter()
        startTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
    }


    // MARK: - Data Loading

    private func loadCurrencies() {
        allCurrencies  = CurrencyDataProvider.generateCurrencies()
        firstCurrency  = allCurrencies.first(where: { $0.code == "USD" }) ?? allCurrencies[0]
        secondCurrency = allCurrencies.first(where: { $0.code == "BTC" }) ?? allCurrencies[1]
    }


    // MARK: - Setup UI

    private func setupPairSelector() {
        firstCurrencyButton.titleLabel?.font = .boldSystemFont(ofSize: Fonts.pairButtonSize)
        firstCurrencyButton.layer.cornerRadius = Layout.buttonCornerRadius
        firstCurrencyButton.layer.borderWidth  = Layout.borderWidth
        firstCurrencyButton.layer.borderColor  = UIColor.clear.cgColor
        firstCurrencyButton.translatesAutoresizingMaskIntoConstraints = false
        firstCurrencyButton.addTarget(self, action: #selector(firstCurrencyTapped), for: .touchUpInside)
        view.addSubview(firstCurrencyButton)

        arrowLabel.text      = "->"
        arrowLabel.font      = .boldSystemFont(ofSize: Fonts.pairButtonSize)
        arrowLabel.textColor = .gray
        arrowLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(arrowLabel)

        secondCurrencyButton.titleLabel?.font = .boldSystemFont(ofSize: Fonts.pairButtonSize)
        secondCurrencyButton.layer.cornerRadius = Layout.buttonCornerRadius
        secondCurrencyButton.layer.borderWidth  = Layout.borderWidth
        secondCurrencyButton.layer.borderColor  = UIColor.clear.cgColor
        secondCurrencyButton.translatesAutoresizingMaskIntoConstraints = false
        secondCurrencyButton.addTarget(self, action: #selector(secondCurrencyTapped), for: .touchUpInside)
        view.addSubview(secondCurrencyButton)

        rateLabel.font          = .systemFont(ofSize: Fonts.rateLabelSize)
        rateLabel.textColor     = .lightGray
        rateLabel.textAlignment = .center
        rateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(rateLabel)

        refreshPairButtons()
    }

    private func setupFavoritesFilter() {
        favoritesFilterView.delegate = self
        favoritesFilterView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(favoritesFilterView)
    }

    private func setupFilterSegment() {
        filterSegment.selectedSegmentIndex = 0
        filterSegment.backgroundColor = UIColor(white: 0.15, alpha: 1)
        filterSegment.selectedSegmentTintColor = UIColor(white: 0.3, alpha: 1)
        filterSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
        filterSegment.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .selected)
        filterSegment.translatesAutoresizingMaskIntoConstraints = false
        filterSegment.addTarget(self, action: #selector(typeFilterChanged), for: .valueChanged)
        view.addSubview(filterSegment)
    }

    private func setupConverter() {
        converterContainer.backgroundColor    = UIColor(white: 0.12, alpha: 1)
        converterContainer.layer.cornerRadius = Layout.containerCornerRadius
        converterContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(converterContainer)

        amountTextField.placeholder = MessagesToUser.placeholder
        amountTextField.placeholderStyle(color: .gray)
        amountTextField.font             = .systemFont(ofSize: Fonts.textFieldSize)
        amountTextField.textColor        = .white
        amountTextField.keyboardType     = .decimalPad
        amountTextField.backgroundColor  = UIColor(white: 0.18, alpha: 1)
        amountTextField.layer.cornerRadius = Layout.buttonCornerRadius
        amountTextField.leftView         = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 0))
        amountTextField.leftViewMode     = .always
        amountTextField.translatesAutoresizingMaskIntoConstraints = false
        amountTextField.addTarget(self, action: #selector(amountChanged), for: .editingChanged)
        converterContainer.addSubview(amountTextField)

        resultLabel.text      = "= ..."
        resultLabel.font      = .boldSystemFont(ofSize: Fonts.textFieldSize)
        resultLabel.textColor = .systemGreen
        resultLabel.translatesAutoresizingMaskIntoConstraints = false
        converterContainer.addSubview(resultLabel)

        timerLabel.font          = .systemFont(ofSize: Fonts.timerLabelSize)
        timerLabel.textColor     = .gray
        timerLabel.textAlignment = .right
        timerLabel.translatesAutoresizingMaskIntoConstraints = false
        converterContainer.addSubview(timerLabel)

        NSLayoutConstraint.activate([
            amountTextField.topAnchor.constraint(equalTo: converterContainer.topAnchor, constant: ConverterLayout.textFieldTop),
            amountTextField.leadingAnchor.constraint(equalTo: converterContainer.leadingAnchor, constant: ConverterLayout.padding),
            amountTextField.widthAnchor.constraint(equalTo: converterContainer.widthAnchor, multiplier: ConverterLayout.textFieldWidthMultiplier),
            amountTextField.heightAnchor.constraint(equalToConstant: ConverterLayout.textFieldHeight),

            resultLabel.centerYAnchor.constraint(equalTo: amountTextField.centerYAnchor),
            resultLabel.leadingAnchor.constraint(equalTo: amountTextField.trailingAnchor, constant: ConverterLayout.padding),
            resultLabel.trailingAnchor.constraint(equalTo: converterContainer.trailingAnchor, constant: -ConverterLayout.padding),

            timerLabel.leadingAnchor.constraint(equalTo: converterContainer.leadingAnchor, constant: ConverterLayout.padding),
            timerLabel.trailingAnchor.constraint(equalTo: converterContainer.trailingAnchor, constant: -ConverterLayout.padding),
            timerLabel.topAnchor.constraint(equalTo: amountTextField.bottomAnchor, constant: ConverterLayout.timerLabelTop),
            timerLabel.bottomAnchor.constraint(equalTo: converterContainer.bottomAnchor, constant: -ConverterLayout.padding)
        ])
    }

    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = CollectionLayout.itemSpacing
        layout.minimumLineSpacing      = CollectionLayout.itemSpacing
        layout.sectionInset = UIEdgeInsets(top: CollectionLayout.sectionInset, left: 0,
                                           bottom: CollectionLayout.sectionInset, right: 0)

        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor    = UIColor(white: 0.10, alpha: 1)
        collectionView.layer.cornerRadius = Layout.containerCornerRadius
        collectionView.register(CurrencyCell.self, forCellWithReuseIdentifier: CurrencyCell.reuseId)
        collectionView.dataSource = self
        collectionView.delegate   = self
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(collectionView)
    }

    private func setupEmptyState() {
        emptyStateLabel.text          = MessagesToUser.emptyFavorites
        emptyStateLabel.font          = .systemFont(ofSize: Fonts.emptyStateSize, weight: .medium)
        emptyStateLabel.textColor     = .gray
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.isHidden      = true
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emptyStateLabel)
    }


    // MARK: - Constraints

    private func makeConstraints() {
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

            rateLabel.topAnchor.constraint(equalTo: firstCurrencyButton.bottomAnchor, constant: Layout.rateLabelTop),
            rateLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            rateLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),

            // Favorites Filter
            favoritesFilterView.topAnchor.constraint(equalTo: rateLabel.bottomAnchor, constant: Layout.elementSpacing),
            favoritesFilterView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            favoritesFilterView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),

            filterSegment.topAnchor.constraint(equalTo: favoritesFilterView.bottomAnchor, constant: Layout.elementSpacing),
            filterSegment.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            filterSegment.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),

            converterContainer.topAnchor.constraint(equalTo: filterSegment.bottomAnchor, constant: Layout.elementSpacing),
            converterContainer.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            converterContainer.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),

            collectionView.topAnchor.constraint(equalTo: converterContainer.bottomAnchor, constant: Layout.elementSpacing),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),
            collectionView.bottomAnchor.constraint(equalTo: safe.bottomAnchor, constant: -Layout.sidePadding),

            emptyStateLabel.centerXAnchor.constraint(equalTo: collectionView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: collectionView.centerYAnchor)
        ])
    }


    // MARK: - Actions

    @objc private func firstCurrencyTapped() {
        editingSlot = editingSlot == 0 ? nil : 0
        refreshPairButtons()
        collectionView.reloadData()
    }

    @objc private func secondCurrencyTapped() {
        editingSlot = editingSlot == 1 ? nil : 1
        refreshPairButtons()
        collectionView.reloadData()
    }

    @objc private func typeFilterChanged() {
        switch filterSegment.selectedSegmentIndex {
        case 1:  currentTypeFilter = .fiat
        case 2:  currentTypeFilter = .crypto
        default: currentTypeFilter = .all
        }
        applyFilters()
    }

    @objc private func amountChanged() {
        updateConverter()
    }


    // MARK: - Logic

    // Favorites and Type filters applying
    private func applyFilters() {
        var result = allCurrencies

        // Type filter
        switch currentTypeFilter {
        case .fiat:   result = result.filter { $0.type == .fiat }
        case .crypto: result = result.filter { $0.type == .crypto }
        case .all:    break
        }

        // Favorites filter
        if isFavoritesFilterOn {
            result = result.filter { favoriteCodes.contains($0.code) }
        }

        displayedCurrencies = result

        let showEmpty = isFavoritesFilterOn && displayedCurrencies.isEmpty
        emptyStateLabel.isHidden = !showEmpty
        collectionView.reloadData()
    }

    private func selectCurrency(_ currency: Currency) {
        guard let slot = editingSlot else { return }

        if slot == 0 {
            if currency == secondCurrency { return }
            firstCurrency = currency
        } else {
            if currency == firstCurrency { return }
            secondCurrency = currency
        }

        editingSlot = nil
        updateRateAndConverter()
        refreshPairButtons()
        collectionView.reloadData()
    }

    private func refreshPairButtons() {
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

    private func updateRateAndConverter() {
        exchangeRate = CurrencyDataProvider.randomRate()
        rateLabel.text = "1 \(firstCurrency.code) = \(String(format: "%.4f", exchangeRate)) \(secondCurrency.code)"
        updateConverter()
    }

    private func updateConverter() {
        guard let text = amountTextField.text,
              let amount = Double(text.replacingOccurrences(of: ",", with: ".")) else {
            resultLabel.text = "= —"
            return
        }
        let result = amount * exchangeRate
        resultLabel.text = "= \(String(format: "%.4f", result)) \(secondCurrency.code)"
    }


    // MARK: - Timer

    private func startTimer() {
        secondsLeft = timerTotalSeconds
        updateTimerUI()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.secondsLeft -= 1
            self.updateTimerUI()

            if self.secondsLeft <= 0 {
                self.secondsLeft = self.timerTotalSeconds
                self.updateRateAndConverter()
            }
        }
    }

    private func updateTimerUI() {
        timerLabel.text = "Обновление через \(secondsLeft) с."
    }
}


// MARK: - FavoritesFilterViewDelegate

extension CurrencyPairViewController: FavoritesFilterViewDelegate {

    func favoritesFilterView(_ view: FavoritesFilterView, didChange isOn: Bool) {
        isFavoritesFilterOn = isOn
        applyFilters()
    }
}


// MARK: - CurrencyCellDelegate

extension CurrencyPairViewController: CurrencyCellDelegate {

    func currencyCell(_ cell: CurrencyCell, didToggleFavorite currency: Currency) {
        if favoriteCodes.contains(currency.code) {
            favoriteCodes.remove(currency.code)
        } else {
            favoriteCodes.insert(currency.code)
        }
        applyFilters()
    }
}


// MARK: - UICollectionViewDataSource

extension CurrencyPairViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return displayedCurrencies.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: CurrencyCell.reuseId, for: indexPath) as! CurrencyCell
        let currency = displayedCurrencies[indexPath.item]

        let isDisabled: Bool
        if editingSlot == 0 {
            isDisabled = (currency == secondCurrency)
        } else if editingSlot == 1 {
            isDisabled = (currency == firstCurrency)
        } else {
            isDisabled = false
        }

        let isFavorite = favoriteCodes.contains(currency.code)
        cell.delegate = self
        cell.configure(with: currency, isDisabled: isDisabled, isFavorite: isFavorite)
        return cell
    }
}


// MARK: - UICollectionViewDelegate

extension CurrencyPairViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        selectCurrency(displayedCurrencies[indexPath.item])
    }
}


// MARK: - UICollectionViewDelegateFlowLayout

extension CurrencyPairViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let totalSpacing = CollectionLayout.itemSpacing * (CollectionLayout.columnCount - 1)
        let width = (collectionView.bounds.width - totalSpacing - CollectionLayout.sectionPadding) / CollectionLayout.columnCount
        return CGSize(width: width, height: CollectionLayout.cellHeight)
    }
}


// MARK: - Constants

private extension CurrencyPairViewController {

    enum MessagesToUser {
        static let title: String          = "Выбор пары"
        static let placeholder: String    = "Введите сумму..."
        static let emptyFavorites: String = "☆ Нет избранных валют.\nДобавьте валюты, нажав на звёздочку."
    }

    enum Layout {
        static let sidePadding: CGFloat               = 16
        static let elementSpacing: CGFloat            = 12
        static let rateLabelTop: CGFloat              = 6
        static let pairButtonHeight: CGFloat          = 48
        static let pairButtonWidthMultiplier: CGFloat = 0.38
        static let buttonCornerRadius: CGFloat        = 10
        static let containerCornerRadius: CGFloat     = 14
        static let borderWidth: CGFloat               = 2
    }

    enum ConverterLayout {
        static let padding: CGFloat                    = 12
        static let textFieldTop: CGFloat               = 12
        static let textFieldHeight: CGFloat            = 36
        static let textFieldWidthMultiplier: CGFloat   = 0.55
        static let timerLabelTop: CGFloat              = 8
    }

    enum CollectionLayout {
        static let itemSpacing: CGFloat    = 8
        static let sectionInset: CGFloat   = 8
        static let sectionPadding: CGFloat = 16
        static let columnCount: CGFloat    = 3
        static let cellHeight: CGFloat     = 56
    }

    enum Fonts {
        static let pairButtonSize: CGFloat  = 22
        static let rateLabelSize: CGFloat   = 14
        static let textFieldSize: CGFloat   = 16
        static let timerLabelSize: CGFloat  = 12
        static let emptyStateSize: CGFloat  = 15
    }
}


// MARK: - UITextField placeholder helper

private extension UITextField {
    func placeholderStyle(color: UIColor) {
        guard let ph = placeholder else { return }
        attributedPlaceholder = NSAttributedString(string: ph, attributes: [.foregroundColor: color])
    }
}
