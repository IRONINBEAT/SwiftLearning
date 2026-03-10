import Foundation

let startCapital: Double = 10 // стартовый капитал 10$
var balance: Double = startCapital
var hasStock: Bool = false // есть ли у нас акция на руках
let stock: String = "AAPL" // наименование акции
var currentPrice: Double = Double.random(in: 5...15) // текущая цена актива
var buyPrice: Double = 0 // цена покупки
var decision: String = "Игнорирование" // решение "Продажа", "Покупка", "Игнорирование"
var income:Double = 0 // доход со сделки

for iter in 1...20 { // для симуляции пустим 20 тиков торговли на бирже
    
    var lastPrice = currentPrice
    currentPrice = Double.random(in: 5...15)
    
    print("--- Итерация \(iter) ---")
    
    if !hasStock && currentPrice < lastPrice && balance > currentPrice { //актива нет, он стал дешевле и у нас есть деньги, чтобы купить актив
        buyPrice = currentPrice
        balance -= currentPrice
        decision = "Покупка"
        hasStock = true
        income = 0
        
        print("\(decision) FROM = \(String(format: "%.2f", lastPrice))$ -> TO = \(String(format: "%.2f", currentPrice))$, INCOME = \(String(format: "%.2f", income))$.")
        // Стоит пояснить. Покупаем, потому что цена упала по сравнению со стартовой, а также у нас хватает денег,
        // чтобы это падение подхватить. Соответственно доходности у нас никакой нет.
    }
    
    else if hasStock && currentPrice > buyPrice { //актив на руках и еще он стал дороже цены его покупки
        balance += currentPrice
        decision = "Продажа"
        hasStock = false
        income = currentPrice - buyPrice
        
        print("\(decision) FROM = \(String(format: "%.2f", lastPrice))$ -> TO = \(String(format: "%.2f", currentPrice))$, INCOME = \(String(format: "%.2f", income))$.")
        // Здесь же получается, что текущая цена получилась выше цены покупки акции, поэтому актив мы сбрасываем и
        // получаем доход равный разнице в цене покупки и продаже.
    }
    else { // цена не уменьшилась по сравнению с предыдущей перед покупкой или не стала выше цены покупки перед продажей
        decision = "Игнорирование"
    }
    
    print("\(String(format: "%.2f", currentPrice))$ \(stock) - \(decision). BALANCE = \(String(format: "%.2f", balance))$\n")
}

print("Итоговый доход: \(String(format: "%.2f", balance - startCapital))$")
