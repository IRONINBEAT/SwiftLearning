import Foundation

//let startCapital: Double = 10 // стартовый капитал 10$
//var balance: Double = startCapital
//var hasStock: Bool = false // есть ли у нас акция на руках
//let stock: String = "AAPL" // наименование акции
//var currentPrice: Double = Double.random(in: 5...15) // текущая цена актива
//var buyPrice: Double = 0 // цена покупки
//var decision: String = "Игнорирование" // решение "Продажа", "Покупка", "Игнорирование"
//var income:Double = 0 // доход со сделки
//
//for iter in 1...20 { // для симуляции пустим 20 тиков торговли на бирже
//    
//    var lastPrice = currentPrice
//    currentPrice = Double.random(in: 5...15)
//    
//    print("--- Итерация \(iter) ---")
//    
//    if !hasStock && currentPrice < lastPrice && balance > currentPrice { //актива нет, он стал дешевле и у нас есть деньги, чтобы купить актив
//        buyPrice = currentPrice
//        balance -= currentPrice
//        decision = "Покупка"
//        hasStock = true
//        income = 0
//        
//        print("\(decision) FROM = \(String(format: "%.2f", lastPrice))$ -> TO = \(String(format: "%.2f", currentPrice))$, INCOME = \(String(format: "%.2f", income))$.")
//        // Стоит пояснить. Покупаем, потому что цена упала по сравнению со стартовой, а также у нас хватает денег,
//        // чтобы это падение подхватить. Соответственно доходности у нас никакой нет.
//    }
//    
//    else if hasStock && currentPrice > buyPrice { //актив на руках и еще он стал дороже цены его покупки
//        balance += currentPrice
//        decision = "Продажа"
//        hasStock = false
//        income = currentPrice - buyPrice
//        
//        print("\(decision) FROM = \(String(format: "%.2f", lastPrice))$ -> TO = \(String(format: "%.2f", currentPrice))$, INCOME = \(String(format: "%.2f", income))$.")
//        // Здесь же получается, что текущая цена получилась выше цены покупки акции, поэтому актив мы сбрасываем и
//        // получаем доход равный разнице в цене покупки и продаже.
//    }
//    else { // цена не уменьшилась по сравнению с предыдущей перед покупкой или не стала выше цены покупки перед продажей
//        decision = "Игнорирование"
//    }
//    
//    print("\(String(format: "%.2f", currentPrice))$ \(stock) - \(decision). BALANCE = \(String(format: "%.2f", balance))$\n")
//}
//
//print("Итоговый доход: \(String(format: "%.2f", balance - startCapital))$")

enum TradeDecision: String {
    case buy = "Покупка"
    case sell = "Продажа"
    case ignore = "Игнорирование"
}

extension Double {
    var twoDigitsAfterDecimalPoint: String {
        return String(format: "%.2f", self)
    }
}

protocol TradingStrategy {
    func makeDecision(stock: Stock) -> TradeDecision
}

struct Stock {
    var currency: String
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

class AITrader: TradingStrategy {
    private(set) var startCapital: Double
    private(set) var balance: Double
    private var hasStock: Bool = false
    private var buyPrice: Double = 0.0
    private(set) var income: Double = 0.0
    
    init (startCapital: Double) {
        self.startCapital = startCapital
        self.balance = startCapital
    }
    
    func executeTrade(stock: Stock) {
        
        var decision = makeDecision(stock: stock)
        
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
        
        print("\(decision.rawValue) FROM = \(stock.lastPrice.twoDigitsAfterDecimalPoint)$ -> TO = \(stock.currentPrice.twoDigitsAfterDecimalPoint)$, INCOME = \(income.twoDigitsAfterDecimalPoint)$.\n")
    }
    
    func makeDecision(stock: Stock) -> TradeDecision {
        if !hasStock && stock.currentPrice < stock.lastPrice && balance >= stock.currentPrice {
            return .buy
        }
        else if hasStock && stock.currentPrice > buyPrice {
            return .sell
        }
        return .ignore
    }
}

class TradeSimulator {
    private var trader: AITrader
    private var stock: Stock
    
    init(trader: AITrader, stock: Stock) {
        self.trader = trader
        self.stock = stock
    }
    
    func runSimulation(numOfTicks: Int) {
        for tick in 1...numOfTicks {
            print("----- Tick №\(tick) -----")
            stock.generateAndUpdatePrice()
            trader.executeTrade(stock: stock)
        }
        
        var totalIncome = trader.balance - trader.startCapital
        print("Итоговый доход: \(totalIncome.twoDigitsAfterDecimalPoint)$")
    }
}

let superGigaAITrader: AITrader = AITrader(startCapital: 10)

let initCurrentPrice = Double.random(in: 5...15)
let stock: Stock = Stock(currency: "BTC", currentPrice: initCurrentPrice)

let tradeSimulator: TradeSimulator = TradeSimulator(trader: superGigaAITrader, stock: stock)
tradeSimulator.runSimulation(numOfTicks: 20)

