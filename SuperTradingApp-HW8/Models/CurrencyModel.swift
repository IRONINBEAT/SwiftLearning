import Foundation

// Type of currency (fiat or crypto)
enum CurrencyType {
    case fiat
    case crypto
}

// Model of one currency
struct Currency: Equatable {
    let code: String
    let type: CurrencyType
    
    // Overriding the Equality Operator
    static func == (lhs: Currency, rhs: Currency) -> Bool {
        return lhs.code == rhs.code
    }
}
