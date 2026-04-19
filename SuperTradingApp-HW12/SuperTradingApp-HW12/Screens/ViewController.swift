import UIKit

final class ViewController: UIViewController {

    private let statsStack = UIStackView()
    private let currentPairButton = UIButton(type: .system)
    private let chartButton = UIButton(type: .system)
    private let pairHintLabel = UILabel()
    private let tableView = UITableView()
    private let runButton = UIButton(type: .system)
    private let emptyStateLabel = UILabel()

    private let startCapital: Double
    private let allCurrencies = CurrencyDataProvider.generateCurrencies()
    private let trader: AITrader

    private var firstCurrency: Currency
    private var secondCurrency: Currency
    private var favoriteCodes: Set<String> = []
    private var trades: [TradeRecord] = []
    private var statsCards: [StatsCardView] = []

    init() {
        let startCapital = 10.0
        let currencies = CurrencyDataProvider.generateCurrencies()
        self.startCapital = startCapital
        self.firstCurrency = currencies.first(where: { $0.code == "USD" }) ?? currencies[0]
        self.secondCurrency = currencies.first(where: { $0.code == "BTC" }) ?? currencies[1]
        self.trader = AITrader(startCapital: startCapital)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = MessagesToUser.screenTitle
        setupNavigationBar()
        setupUI()
        makeConstraints()
        setupChartAccess()
        refreshCurrentPairUI()
        resetTradingState()
    }
}

// MARK: - Actions

private extension ViewController {

    @objc func runTapped() {
        guard canRunSimulation else { return }

        prepareForSimulation()
        runSimulation()
        updateTradingSummary()
        scrollToLastTradeIfNeeded()
    }

    @objc func pairTapped() {
        let quickPicker = QuickCurrencyPickerViewController(
            allCurrencies: allCurrencies,
            firstCurrency: firstCurrency,
            secondCurrency: secondCurrency,
            favoriteCodes: favoriteCodes
        )

        quickPicker.onPairChanged = { [weak self] firstCurrency, secondCurrency in
            self?.applyPairChange(firstCurrency: firstCurrency, secondCurrency: secondCurrency)
        }

        quickPicker.onFavoritesChanged = { [weak self] favoriteCodes in
            self?.favoriteCodes = favoriteCodes
        }

        quickPicker.onShowAllRequested = { [weak self] firstCurrency, secondCurrency, favoriteCodes in
            guard let self else { return }
            self.favoriteCodes = favoriteCodes
            self.dismiss(animated: true) {
                self.showFullCurrencyPicker(firstCurrency: firstCurrency, secondCurrency: secondCurrency)
            }
        }

        let navigationController = UINavigationController(rootViewController: quickPicker)
        navigationController.modalPresentationStyle = .pageSheet
        if let sheet = navigationController.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }

        present(navigationController, animated: true)
    }

    @objc func resetButtonTapped() {
        resetTradingState()
    }

    @objc func randomPairButtonTapped() {
        let randomCurrencies = allCurrencies.shuffled()
        guard randomCurrencies.count > 1 else { return }
        applyPairChange(firstCurrency: randomCurrencies[0], secondCurrency: randomCurrencies[1])
    }

    @objc func chartButtonTapped() {
        let chartViewController = ChartViewController()
        navigationController?.pushViewController(chartViewController, animated: true)
    }

    @objc func handleChartSwipe() {
        chartButtonTapped()
    }
}

// MARK: - Navigation

private extension ViewController {

    func setupNavigationBar() {
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "trash"),
            style: .plain,
            target: self,
            action: #selector(resetButtonTapped)
        )

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "shuffle"),
            style: .plain,
            target: self,
            action: #selector(randomPairButtonTapped)
        )
    }

    func showFullCurrencyPicker(firstCurrency: Currency, secondCurrency: Currency) {
        let currencyPairViewController = CurrencyPairViewController(
            allCurrencies: allCurrencies,
            firstCurrency: firstCurrency,
            secondCurrency: secondCurrency,
            favoriteCodes: favoriteCodes
        )

        currencyPairViewController.onPairChanged = { [weak self] firstCurrency, secondCurrency in
            self?.applyPairChange(firstCurrency: firstCurrency, secondCurrency: secondCurrency)
        }

        currencyPairViewController.onFavoritesChanged = { [weak self] favoriteCodes in
            self?.favoriteCodes = favoriteCodes
        }

        navigationController?.pushViewController(currencyPairViewController, animated: true)
    }
}

// MARK: - State

private extension ViewController {

    var canRunSimulation: Bool {
        true
    }

    func applyPairChange(firstCurrency: Currency, secondCurrency: Currency) {
        guard self.firstCurrency != firstCurrency || self.secondCurrency != secondCurrency else { return }

        self.firstCurrency = firstCurrency
        self.secondCurrency = secondCurrency
        refreshCurrentPairUI()
        resetTradingState()
    }

    func refreshCurrentPairUI() {
        let title = "\(firstCurrency.code) - \(secondCurrency.code)"
        currentPairButton.setTitle(title, for: .normal)
    }

    func resetTradingState() {
        trader.reset()
        trades = []
        reloadTrades()
        emptyStateLabel.isHidden = false
        updateStatsCardsForInitialState()
    }

    func prepareForSimulation() {
        emptyStateLabel.isHidden = true
    }

    func runSimulation() {
        let stock = Stock(currency: "\(firstCurrency.code)-\(secondCurrency.code)", currentPrice: Double.random(in: 5...15))
        let simulator = TradeSimulator(trader: trader, stock: stock)
        trades = simulator.runSimulation(numOfTicks: 50)
        reloadTrades()
    }

    func updateTradingSummary() {
        let income = trader.balance - trader.startCapital
        updateCard(at: 1, value: "\(trader.balance.twoDigits)$", color: .white)
        updateCard(at: 2, value: "\(income >= 0 ? "+" : "")\(income.twoDigits)$", color: income >= 0 ? .systemGreen : .systemRed)
    }

    func scrollToLastTradeIfNeeded() {
        guard !trades.isEmpty else { return }
        tableView.scrollToRow(at: IndexPath(row: trades.count - 1, section: 0), at: .bottom, animated: true)
    }

    func reloadTrades() {
        tableView.reloadData()
    }

    func updateStatsCardsForInitialState() {
        updateCard(at: 0, value: "\(startCapital.twoDigits)$", color: .white)
        updateCard(at: 1, value: "—", color: .white)
        updateCard(at: 2, value: "—", color: .white)
    }

    func updateCard(at index: Int, value: String, color: UIColor) {
        guard statsCards.indices.contains(index) else { return }
        statsCards[index].updateValue(value, color: color)
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate

extension ViewController: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        trades.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: TradeCell.reuseId, for: indexPath) as? TradeCell else {
            return UITableViewCell()
        }
        cell.configure(with: trades[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let trade = trades[indexPath.row]
        return trade.isTradeExecuted ? Layout.tableViewExecutedRowHeight : Layout.tableViewRowHeight
    }
}

// MARK: - UI

private extension ViewController {

    func setupUI() {
        view.backgroundColor = .black
        setupStatsStack()
        setupCurrentPairButton()
        setupChartButton()
        setupPairHintLabel()
        setupTableView()
        setupEmptyStateLabel()
        setupRunButton()
    }

    func setupStatsStack() {
        statsStack.axis = .horizontal
        statsStack.distribution = .fillEqually
        statsStack.spacing = Layout.statsStackSpacing
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statsStack)

        for title in ["Капитал", "Баланс", "Доход"] {
            let card = StatsCardView(title: title)
            statsCards.append(card)
            statsStack.addArrangedSubview(card)
        }
    }

    func setupCurrentPairButton() {
        currentPairButton.backgroundColor = UIColor(white: 0.12, alpha: 1)
        currentPairButton.layer.cornerRadius = Layout.cornerRadius
        currentPairButton.layer.borderWidth = 1
        currentPairButton.layer.borderColor = UIColor.systemBlue.cgColor
        currentPairButton.setTitleColor(.white, for: .normal)
        currentPairButton.titleLabel?.font = .boldSystemFont(ofSize: Fonts.pairFontSize)
        currentPairButton.addTarget(self, action: #selector(pairTapped), for: .touchUpInside)
        currentPairButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(currentPairButton)
    }

    func setupPairHintLabel() {
        pairHintLabel.text = MessagesToUser.pairHint
        pairHintLabel.font = .systemFont(ofSize: Fonts.hintFontSize)
        pairHintLabel.textColor = .lightGray
        pairHintLabel.textAlignment = .center
        pairHintLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pairHintLabel)
    }

    func setupChartButton() {
        var configuration = UIButton.Configuration.filled()
        configuration.title = MessagesToUser.chartButtonTitle
        configuration.image = UIImage(systemName: "chart.bar.xaxis")
        configuration.imagePadding = 8
        configuration.baseBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.9)
        configuration.baseForegroundColor = .white
        configuration.cornerStyle = .large

        chartButton.configuration = configuration
        chartButton.addTarget(self, action: #selector(chartButtonTapped), for: .touchUpInside)
        chartButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(chartButton)
    }

    func setupTableView() {
        tableView.backgroundColor = UIColor(white: 0.10, alpha: 1)
        tableView.layer.cornerRadius = Layout.cornerRadius
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .gray.withAlphaComponent(0.3)
        tableView.register(TradeCell.self, forCellReuseIdentifier: TradeCell.reuseId)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
    }

    func setupEmptyStateLabel() {
        emptyStateLabel.text = MessagesToUser.startMessage
        emptyStateLabel.font = .systemFont(ofSize: Fonts.textFontSize, weight: .medium)
        emptyStateLabel.textColor = .gray
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.numberOfLines = 0
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.addSubview(emptyStateLabel)
    }

    func setupRunButton() {
        runButton.setTitle(MessagesToUser.buttonText, for: .normal)
        runButton.backgroundColor = .systemGreen
        runButton.setTitleColor(.white, for: .normal)
        runButton.titleLabel?.font = .boldSystemFont(ofSize: Fonts.textFontSize)
        runButton.layer.cornerRadius = Layout.buttonCornerRadius
        runButton.addTarget(self, action: #selector(runTapped), for: .touchUpInside)
        runButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(runButton)
    }

    func setupChartAccess() {
        let swipeGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleChartSwipe))
        swipeGesture.direction = .up
        view.addGestureRecognizer(swipeGesture)
    }

    func makeConstraints() {
        NSLayoutConstraint.activate([
            statsStack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Layout.elementSpacing),
            statsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            statsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),

            currentPairButton.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: Layout.elementSpacing),
            currentPairButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            currentPairButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),
            currentPairButton.heightAnchor.constraint(equalToConstant: Layout.pairButtonHeight),

            chartButton.topAnchor.constraint(equalTo: currentPairButton.bottomAnchor, constant: Layout.elementSpacing),
            chartButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            chartButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),
            chartButton.heightAnchor.constraint(equalToConstant: Layout.secondaryButtonHeight),

            pairHintLabel.topAnchor.constraint(equalTo: chartButton.bottomAnchor, constant: Layout.hintTopSpacing),
            pairHintLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            pairHintLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),

            tableView.topAnchor.constraint(equalTo: pairHintLabel.bottomAnchor, constant: Layout.elementSpacing),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),
            tableView.bottomAnchor.constraint(equalTo: runButton.topAnchor, constant: -Layout.elementSpacing),

            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            emptyStateLabel.leadingAnchor.constraint(greaterThanOrEqualTo: tableView.leadingAnchor, constant: Layout.sidePadding),
            emptyStateLabel.trailingAnchor.constraint(lessThanOrEqualTo: tableView.trailingAnchor, constant: -Layout.sidePadding),

            runButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            runButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),
            runButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.elementSpacing),
            runButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight)
        ])
    }
}

private extension ViewController {

    enum MessagesToUser {
        static let screenTitle = "Торговля"
        static let startMessage = "Нет данных по выбранной паре.\nНажмите на блок валют или запустите симуляцию."
        static let buttonText = "RUN SIMULATION"
        static let chartButtonTitle = "График"
        static let pairHint = "Нажмите на пару для выбора валют, на кнопку графика для свечей или сделайте свайп вверх"
    }

    enum Layout {
        static let statsStackSpacing: CGFloat = 10
        static let cornerRadius: CGFloat = 14
        static let buttonCornerRadius: CGFloat = 10
        static let sidePadding: CGFloat = 16
        static let elementSpacing: CGFloat = 20
        static let hintTopSpacing: CGFloat = 8
        static let buttonHeight: CGFloat = 54
        static let secondaryButtonHeight: CGFloat = 50
        static let pairButtonHeight: CGFloat = 58
        static let tableViewExecutedRowHeight: CGFloat = 90
        static let tableViewRowHeight: CGFloat = 60
    }

    enum Fonts {
        static let pairFontSize: CGFloat = 24
        static let hintFontSize: CGFloat = 13
        static let textFontSize: CGFloat = 16
    }
}

private final class StatsCardView: UIView {

    private let titleLabel = UILabel()
    private let valueLabel = UILabel()

    init(title: String) {
        super.init(frame: .zero)
        setupView()
        setupTitleLabel(with: title)
        setupValueLabel()
        setupConstraints()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateValue(_ value: String, color: UIColor) {
        valueLabel.text = value
        valueLabel.textColor = color
    }
}

private extension StatsCardView {

    func setupView() {
        backgroundColor = UIColor(white: 0.15, alpha: 1)
        layer.cornerRadius = 14
    }

    func setupTitleLabel(with title: String) {
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 16)
        titleLabel.textColor = .lightGray
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
    }

    func setupValueLabel() {
        valueLabel.font = .boldSystemFont(ofSize: 16)
        valueLabel.textColor = .white
        valueLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(valueLabel)
    }

    func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor, constant: 10),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            valueLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10)
        ])
    }
}
