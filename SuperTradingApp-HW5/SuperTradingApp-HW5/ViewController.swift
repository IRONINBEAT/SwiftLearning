import UIKit

final class ViewController: UIViewController {
    
    private let titleLabel = UILabel()
    private let statsStack = UIStackView()
    private let logView = UIView()
    private let emptyStateLabel = UILabel()
    private let logTextView = UITextView()
    private let runButton = UIButton(type: .system)
    
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
        
        logTextView.text = sim.runSimulation(numOfTicks: 20).joined(separator: "\n")
        let range = NSMakeRange(logTextView.text.count - 1, 1)
        logTextView.scrollRangeToVisible(range)
        
        let income = trader.balance - trader.startCapital
        updateCard(index: 1, value: "\(trader.balance.twoDigits)$", color: .white)
        updateCard(index: 2, value: "\(income >= 0 ? "+" : "")\(income.twoDigits)$", color: income >= 0 ? .systemGreen : .systemRed)
    }
    
    private func updateCard(index: Int, value: String, color: UIColor) {
        let card = statsStack.arrangedSubviews[index]
        if let lbl = card.viewWithTag(1) as? UILabel {
            lbl.text = value
            lbl.textColor = color
        }
    }
}

// MARK: - UI Setup
private extension ViewController {
    
    enum MessagesToUser {
        // State log
        static let startMessage: String = "Нет данных..."
        
        // Title
        static let appTitle: String = "SuperGiga Trading Bot"
        
        // Button
        static let buttonText: String = "RUN SIMULATION"
    }
    
    enum Layout {
        // Title
        static let titleFontSize: CGFloat = 22
        
        // Text
        static let textFontSize: CGFloat = 16
        
        // Stats Stack
        static let statsStackSpacing: CGFloat = 10
        
        // Log View
        static let logViewCornerRadius: CGFloat = 14
        static let logViewTextFontSize: CGFloat = 12
        
        // Button
        static let buttonCornerRadius: CGFloat = 10
        
        // Constraints
        static let sidePadding: CGFloat = 16
        static let elementSpacing: CGFloat = 20
        static let logInternalPadding: CGFloat = 10
        static let buttonHeight: CGFloat = 54
        
        // Stat Card Constraints
        static let cardPadding: CGFloat = 10
        static let cardValueTop: CGFloat = 4
    }
    
    func setupUI() {
        view.backgroundColor = .black
        
        [titleLabel, statsStack, logView, logTextView, runButton, emptyStateLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview($0)
        }
        
        // title setup
        titleLabel.text = MessagesToUser.appTitle
        titleLabel.font = .boldSystemFont(ofSize: Layout.titleFontSize)
        titleLabel.textColor = .white
        
        // statsStack setup
        statsStack.axis = .horizontal
        statsStack.distribution = .fillEqually
        statsStack.spacing = Layout.statsStackSpacing
        
        for title in ["Капитал", "Баланс", "Доход"] {
            let card = createCard(title: title)
            statsStack.addArrangedSubview(card)
        }
        
        // Log setup
        logView.backgroundColor = UIColor(white: 0.10, alpha: 1)
        logView.layer.cornerRadius = Layout.logViewCornerRadius
        
        logTextView.backgroundColor = UIColor(white: 0.15, alpha: 1)
        logTextView.layer.cornerRadius = Layout.logViewCornerRadius
        logTextView.isEditable = false
        logTextView.textColor = UIColor(white: 0.75, alpha: 1)
        logTextView.font = .monospacedSystemFont(ofSize: Layout.logViewTextFontSize, weight: .bold)
        logTextView.text = ""
        
        logView.addSubview(logTextView)
        logView.addSubview(emptyStateLabel)
        
        // Empty State Label setup
        emptyStateLabel.text = MessagesToUser.startMessage
        emptyStateLabel.font = .systemFont(ofSize: Layout.textFontSize, weight: .medium)
        emptyStateLabel.textColor = .gray
        emptyStateLabel.textAlignment = .center
        
        // Button setup
        runButton.setTitle(MessagesToUser.buttonText, for: .normal)
        runButton.backgroundColor = .systemGreen
        runButton.setTitleColor(.white, for: .normal)
        runButton.titleLabel?.font = .boldSystemFont(ofSize: Layout.textFontSize)
        runButton.layer.cornerRadius = Layout.buttonCornerRadius
        runButton.addTarget(self, action: #selector(runTapped), for: .touchUpInside)
    }
    
    private func createCard(title: String) -> UIView {
        let card = UIView()
        card.backgroundColor = UIColor(white: 0.15, alpha: 1)
        card.layer.cornerRadius = Layout.logViewCornerRadius
        
        let lbl = UILabel()
        lbl.text = title
        lbl.font = .systemFont(ofSize: Layout.textFontSize)
        lbl.textColor = .lightGray
        lbl.translatesAutoresizingMaskIntoConstraints = false
        
        let val = UILabel()
        val.text = title == "Капитал" ? "10.00$" : "—"
        val.font = .boldSystemFont(ofSize: Layout.textFontSize)
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
            // Title
            titleLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: Layout.elementSpacing),
            titleLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            titleLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),
            
            // Stats
            statsStack.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: Layout.elementSpacing),
            statsStack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            statsStack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),
            
            // Log Container
            logView.topAnchor.constraint(equalTo: statsStack.bottomAnchor, constant: Layout.elementSpacing),
            logView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            logView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),
            logView.bottomAnchor.constraint(equalTo: runButton.topAnchor, constant: -Layout.elementSpacing),
            
            // Empty State
            emptyStateLabel.centerXAnchor.constraint(equalTo: logView.centerXAnchor),
            emptyStateLabel.centerYAnchor.constraint(equalTo: logView.centerYAnchor),
            
            // Log Text
            logTextView.topAnchor.constraint(equalTo: logView.topAnchor, constant: Layout.logInternalPadding),
            logTextView.leadingAnchor.constraint(equalTo: logView.leadingAnchor, constant: Layout.logInternalPadding),
            logTextView.trailingAnchor.constraint(equalTo: logView.trailingAnchor, constant: -Layout.logInternalPadding),
            logTextView.bottomAnchor.constraint(equalTo: logView.bottomAnchor, constant: -Layout.logInternalPadding),
            
            // Button
            runButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: Layout.sidePadding),
            runButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -Layout.sidePadding),
            runButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -Layout.elementSpacing),
            runButton.heightAnchor.constraint(equalToConstant: Layout.buttonHeight)
        ])
    }
}
