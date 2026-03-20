import UIKit

final class ViewController: UIViewController {

    private let titleLabel = UILabel()
    private let statsStack = UIStackView()
    private let logView = UIView()
    private let logTextView = UITextView()
    private let runButton = UIButton(type: .system)


    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .black

        addTitleLabel()
        addStatsStack()
        addLogView()
        addRunButton()
    }


    private func addTitleLabel() {
        titleLabel.text = "SuperGiga Trading Bot"
        titleLabel.font = .boldSystemFont(ofSize: 22)
        titleLabel.textColor = .white
        titleLabel.frame = CGRect(x: 16, y: 60, width: view.bounds.width - 32, height: 40)
        view.addSubview(titleLabel)
    }

    private func addStatsStack() {
        statsStack.axis = .horizontal
        statsStack.distribution = .fillEqually
        statsStack.spacing = 10
        statsStack.frame = CGRect(x: 16, y: 110, width: view.bounds.width - 32, height: 60)

        for title in ["Капитал", "Баланс", "Доход"] {
            let card = UIView()
            card.backgroundColor = UIColor(white: 0.15, alpha: 1)
            card.layer.cornerRadius = 14

            let lbl = UILabel()
            lbl.text = title
            lbl.font = .systemFont(ofSize: 12)
            lbl.textColor = .lightGray
            lbl.frame = CGRect(x: 8, y: 8, width: 80, height: 16)

            let val = UILabel()
            val.text = title == "Капитал" ? "$10.00" : "—"
            val.font = .boldSystemFont(ofSize: 14)
            val.textColor = .white
            val.tag = 1
            val.frame = CGRect(x: 8, y: 30, width: 80, height: 20)

            card.addSubview(lbl)
            card.addSubview(val)
            statsStack.addArrangedSubview(card)
        }

        view.addSubview(statsStack)
    }

    private func addLogView() {
        // Внешний View
        logView.backgroundColor = UIColor(white: 0.10, alpha: 1)
        logView.layer.cornerRadius = 14
        logView.frame = CGRect(x: 16, y: 185, width:  view.bounds.width - 32, height: view.bounds.height - 310)
        view.addSubview(logView)

        // Вложенный View внутри logView
        let innerView = UIView()
        innerView.backgroundColor = UIColor(white: 0.15, alpha: 1)
        innerView.layer.cornerRadius = 14
        innerView.frame = CGRect(x: 10, y: 10, width:  logView.bounds.width  - 20, height: logView.bounds.height - 20)
        logView.addSubview(innerView)

        // UITextView внутри innerView
        logTextView.backgroundColor = .clear
        logTextView.isEditable = false
        logTextView.font = .boldSystemFont(ofSize: 12)
        logTextView.textColor = UIColor(white: 0.75, alpha: 1)
        logTextView.text = "Нажмите кнопку 'RUN SIMULATION',\nчтобы запустить симуляцию..."
        logTextView.frame = CGRect(x: 8, y: 8, width:  innerView.bounds.width  - 16, height: innerView.bounds.height - 16)
        innerView.addSubview(logTextView)
    }

    private func addRunButton() {
        runButton.setTitle("RUN SIMULATION", for: .normal)
        runButton.setTitleColor(.white, for: .normal)
        runButton.titleLabel?.font = .boldSystemFont(ofSize: 16)
        runButton.backgroundColor = .systemGreen
        runButton.layer.cornerRadius = 14
        runButton.frame = CGRect(x: 16, y: view.bounds.height - 100, width:  view.bounds.width - 32, height: 54)
        runButton.addTarget(self, action: #selector(runTapped), for: .touchUpInside)
        view.addSubview(runButton)
    }

    @objc private func runTapped() {
        let trader = AITrader(startCapital: 10)
        let stock = Stock(currency: "BTC", currentPrice: Double.random(in: 5...15))
        let sim = TradeSimulator(trader: trader, stock: stock)

        logTextView.text = sim.runSimulation(numOfTicks: 20).joined(separator: "\n")

        // Обновляем карточки Баланс и Доход
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
