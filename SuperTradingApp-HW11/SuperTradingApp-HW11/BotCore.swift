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

struct TradeRecord {
    let tickNumber: Int
    let decision: TradeDecision
    let lastPrice: Double
    let currentPrice: Double
    let income: Double?
    let buyPrice: Double?
    
    var isTradeExecuted: Bool {
        return decision == .buy || decision == .sell
    }
}

final class AITrader {
    private(set) var startCapital: Double
    private(set) var balance: Double
    private var hasStock = false
    private var buyPrice: Double = .zero
    private(set) var income: Double = .zero
    private(set) var trades: [TradeRecord] = []
    
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
    
    func executeTrade(stock: Stock, tickNumber: Int) -> TradeRecord {
        let decision = makeDecision(stock: stock)
        var tradeIncome: Double? = .zero
        var tradeBuyPrice: Double? = .zero
        
        switch decision {
        case .buy:
            hasStock = true
            buyPrice = stock.currentPrice
            balance -= stock.currentPrice
            income = .zero
            tradeBuyPrice = stock.currentPrice
        case .sell:
            hasStock = false
            balance += stock.currentPrice
            income = stock.currentPrice - buyPrice
            tradeIncome = income
        case .ignore:
            break
        }
        
        let record = TradeRecord(
            tickNumber: tickNumber,
            decision: decision,
            lastPrice: stock.lastPrice,
            currentPrice: stock.currentPrice,
            income: tradeIncome,
            buyPrice: tradeBuyPrice
        )
        
        trades.append(record)
        return record
    }
    
    func reset() {
        balance = startCapital
        hasStock = false
        buyPrice = .zero
        income = .zero
        trades.removeAll()
    }
}

class TradeSimulator {
    private var trader: AITrader
    private var stock: Stock
    
    init(trader: AITrader, stock: Stock) {
        self.trader = trader
        self.stock = stock
    }
    
    func runSimulation(numOfTicks: Int) -> [TradeRecord] {
        trader.reset()
        
        for tick in .zero..<numOfTicks {
            stock.generateAndUpdatePrice()
            _ = trader.executeTrade(stock: stock, tickNumber: tick + 1)
        }
        
        return trader.trades
    }
}
