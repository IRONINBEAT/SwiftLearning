import UIKit

final class ViewController: UIViewController {
    
    private let titleLabel = UILabel()
    private let statsStack = UIStackView()
    private let tableView = UITableView()
    private let runButton = UIButton(type: .system)
    
    private var trades: [TradeRecord] = []
    private let emptyStateLabel = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        makeConstraints()
    }
}

// MARK: - Logic
private extension ViewController {
    
    @objc private func runTapped() {
        emptyStateLabel.isHidden = true
        
        let trader = AITrader(startCapital: 10)
        let stock = Stock(currency: "BTC", currentPrice: Double.random(in: 5...15))
        let sim = TradeSimulator(trader: trader, stock: stock)
        
        trades = sim.runSimulation(numOfTicks: 50)
        tableView.reloadData()
        
        let income = trader.balance - trader.startCapital
        updateCard(index: 1, value: "\(trader.balance.twoDigits)$", color: .white)
        updateCard(index: 2, value: "\(income >= 0 ? "+" : "")\(income.twoDigits)$", color: income >= 0 ? .systemGreen : .systemRed)
        
        if trades.count > 0 {
            tableView.scrollToRow(at: IndexPath(row: trades.count - 1, section: 0), at: .bottom, animated: true)
        }
    }
    
    private func updateCard(index: Int, value: String, color: UIColor) {
        let card = statsStack.arrangedSubviews[index]
        if let lbl = card.viewWithTag(1) as? UILabel {
            lbl.text = value
            lbl.textColor = color
        }
    }
}

// MARK: - UITableViewDataSource & UITableViewDelegate
extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return trades.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "TradeCell", for: indexPath) as! TradeCell
        cell.configure(with: trades[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let trade = trades[indexPath.row]
        return trade.isTradeExecuted ? Layout.tableViewExecitedRowHeight : Layout.tableViewRowHeight
    }
}

// MARK: - UI Setup
private extension ViewController {
    
    func setupUI() {
        view.backgroundColor = .black
        
        // Title
        titleLabel.text = MessagesToUser.appTitle
        titleLabel.font = .boldSystemFont(ofSize: Fonts.titleFontSize)
        titleLabel.textColor = .white
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(titleLabel)
        
        // Stats Stack
        statsStack.axis = .horizontal
        statsStack.distribution = .fillEqually
        statsStack.spacing = Layout.statsStackSpacing
        statsStack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(statsStack)
        
        for title in ["Капитал", "Баланс", "Доход"] {
            let card = createCard(title: title)
            statsStack.addArrangedSubview(card)
        }
        
        // Table View
        tableView.backgroundColor = UIColor(white: 0.10, alpha: 1)
        tableView.layer.cornerRadius = Layout.cornerRadius
        tableView.separatorStyle = .singleLine
        tableView.separatorColor = .gray.withAlphaComponent(0.3)
        tableView.register(TradeCell.self, forCellReuseIdentifier: "TradeCell")
        tableView.dataSource = self
        tableView.delegate = self
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        
        // Empty State Label
        emptyStateLabel.text = MessagesToUser.startMessage
        emptyStateLabel.font = .systemFont(ofSize: Fonts.textFontSize, weight: .medium)
        emptyStateLabel.textColor = .gray
        emptyStateLabel.textAlignment = .center
        emptyStateLabel.translatesAutoresizingMaskIntoConstraints = false
        tableView.addSubview(emptyStateLabel)
        
        // Button
        runButton.setTitle(MessagesToUser.buttonText, for: .normal)
        runButton.backgroundColor = .systemGreen
        runButton.setTitleColor(.white, for: .normal)
        runButton.titleLabel?.font = .boldSystemFont(ofSize: Fonts.textFontSize)
        runButton.layer.cornerRadius = Layout.buttonCornerRadius
        runButton.addTarget(self, action: #selector(runTapped), for: .touchUpInside)
        runButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(runButton)
    }
    
    private func createCard(title: String) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(white: 0.15, alpha: 1)
        card.layer.cornerRadius = Layout.cornerRadius
        
        let lbl = UILabel()
        lbl.text = title
        lbl.font = .systemFont(ofSize: Fonts.textFontSize)
        lbl.textColor = .lightGray
        lbl.translatesAutoresizingMaskIntoConstraints = false
        
        let val = UILabel()
        val.text = title == "Капитал" ? "10.00$" : "—"
        val.font = .boldSystemFont(ofSize: Fonts.textFontSize)
        val.textColor = .white
        val.tag = 1
        val.translatesAutoresizingMaskIntoConstraints = false
        
        card.addSubview(lbl)
        card.addSubview(val)
        
        NSLayoutConstraint.activate([
            lbl.topAnchor.constraint(equalTo: card.topAnchor, constant: Layout.cardPadding),
            lbl.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: Layout.cardPadding),
            
            val.topAnchor.constraint(equalTo: lbl.bottomAnchor, constant: Layout.cardValueTop),
            val.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: Layout.cardPadding),
            val.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -Layout.cardPadding)
        ])
        
        return card
    }
    
    func makeConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Layout.elementSpacing),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),
            
            statsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Layout.elementSpacing),
            statsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            statsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),
            
            tableView.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: Layout.elementSpacing),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),
            tableView.bottomAnchor.constraint(equalTo: runButton.topAnchor, constant: -Layout.elementSpacing),
            
            emptyStateLabel.centerXAnchor.constraint(equalTo: tableView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: tableView.centerYAnchor),
            
            runButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            runButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),
            runButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.elementSpacing),
            runButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight)
        ])
    }
}

private extension ViewController {
    
    enum MessagesToUser {
        static let startMessage: String = "Нет данных..."
        static let appTitle: String = "SuperGiga Trading Bot"
        static let buttonText: String = "RUN SIMULATION"
    }
    
    enum Layout {
        static let statsStackSpacing: CGFloat = 10
        static let cornerRadius: CGFloat = 14
        static let buttonCornerRadius: CGFloat = 10
        static let sidePadding: CGFloat = 16
        static let elementSpacing: CGFloat = 20
        static let buttonHeight: CGFloat = 54
        static let cardPadding: CGFloat = 10
        static let cardValueTop: CGFloat = 4
        static let tableViewExecitedRowHeight: CGFloat = 90
        static let tableViewRowHeight: CGFloat = 60
    }
    
    enum Fonts {
        static let titleFontSize: CGFloat = 22
        static let textFontSize: CGFloat = 16
    }
}
