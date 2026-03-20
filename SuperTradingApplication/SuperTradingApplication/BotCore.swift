import Foundation


enum TradeDecision: String {
    case buy = "Покупка"
    case sell = "Продажа"
    case ignore = "Игнорирование"
}


extension Double {
    var twoDigits: String {
        return String(format: "%.2f", self)
    }
}

struct Stock {
    let currency: String
    var lastPrice: Double
    var currentPrice: Double

    init(currency: String, currentPrice: Double) {
        self.currency = currency
        self.currentPrice = currentPrice
        self.lastPrice = currentPrice
    }

    mutating func generateAndUpdatePrice() {
        lastPrice = currentPrice
        currentPrice = Double.random(in: 5...15)
    }
}

final class AITrader {
    private(set) var startCapital: Double
    private(set) var balance: Double
    private var hasStock = false
    private var buyPrice = 0.0
    private(set) var income = 0.0

    init(startCapital: Double) {
        self.startCapital = startCapital
        self.balance = startCapital
    }

    func makeDecision(stock: Stock) -> TradeDecision {
        if !hasStock && stock.currentPrice < stock.lastPrice && balance >= stock.currentPrice {
            return .buy
        } else if hasStock && stock.currentPrice > buyPrice {
            return .sell
        }
        return .ignore
    }

    func executeTrade(stock: Stock) -> String {
        let decision = makeDecision(stock: stock)

        switch decision {
        case .buy:
            hasStock = true
            buyPrice = stock.currentPrice
            balance -= stock.currentPrice
            income = 0
        case .sell:
            hasStock = false
            balance += stock.currentPrice
            income = stock.currentPrice - buyPrice
        case .ignore:
            break
        }

        return "\(decision.rawValue) FROM = \(stock.lastPrice.twoDigits)$ -> TO \(stock.currentPrice.twoDigits)$, INCOME = \(income.twoDigits)$"
    }
}

class TradeSimulator {
    private var trader: AITrader
    private var stock: Stock

    init(trader: AITrader, stock: Stock) {
        self.trader = trader
        self.stock = stock
    }

    func runSimulation(numOfTicks: Int) -> [String] {
        var log: [String] = []

        log.append("Стартовый капитал: \(trader.startCapital.twoDigits)$")
        log.append("Ticker: \(stock.currency)")
        log.append(String(repeating: "-", count: 30))

        for tick in 0..<numOfTicks {
            log.append("------ Tick №\(tick + 1) ------")
            stock.generateAndUpdatePrice()
            log.append(trader.executeTrade(stock: stock))
        }

        log.append(String(repeating: "-", count: 30))
        let total = trader.balance - trader.startCapital
        log.append("Итоговый доход: \(total >= 0 ? "+" : "")\(total.twoDigits)$")
        log.append("Баланс: \(trader.balance.twoDigits)$")

        return log
    }
}
