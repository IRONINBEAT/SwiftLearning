import Foundation

final class CurrencyDataProvider {

    static let popularCurrencyCodes = [
        "USD", "EUR", "GBP", "JPY", "BTC",
        "ETH", "BNB", "SOL", "XRP", "ADA"
    ]

    static func generateCurrencies() -> [Currency] {
        var currencies: [Currency] = []

        // Fiat currencies
        let fiats = [
            "USD", "EUR", "GBP", "JPY", "CHF", "CAD", "AUD", "CNY", "RUB", "KRW",
            "INR", "BRL", "MXN", "SGD", "HKD", "NOK", "SEK", "DKK", "PLN", "CZK",
            "HUF", "TRY", "ZAR", "NZD", "PHP", "THB", "IDR", "MYR", "AED", "SAR"
        ]
        currencies += fiats.map { Currency(code: $0, type: .fiat) }

        // Crypto currencies
        let cryptos = [
            "BTC", "ETH", "BNB", "SOL", "XRP", "ADA", "DOT", "AVAX", "MATIC", "LINK",
            "UNI", "ATOM", "LTC", "BCH", "XLM", "ALGO", "VET", "FIL", "THETA", "TRX",
            "DOGE", "SHIB", "APT", "ARB", "OP", "TON", "ICP", "FTM", "NEAR", "SAND"
        ]
        currencies += cryptos.map { Currency(code: $0, type: .crypto) }

        // Currency generator
        while currencies.count < 100 {
            let code = randomTicker()
            if !currencies.contains(where: { $0.code == code }) {
                currencies.append(Currency(code: code, type: .crypto))
            }
        }

        return currencies.sorted { $0.code < $1.code }
    }

    // Currency generator (3-5 letters)
    private static func randomTicker() -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        let length = Int.random(in: 3...5)
        return String((0..<length).map { _ in letters.randomElement()! })
    }

    // Random exchange rate
    static func randomRate() -> Double {
        return Double.random(in: 0.01...100)
    }
}
