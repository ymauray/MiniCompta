import Foundation
import Observation

@Observable
@MainActor
final class DeviseStore {
    static let shared = DeviseStore()
    
    private let keyDevise = "app.devise_code"
    
    var codeDevise: String {
        didSet {
            UserDefaults.standard.set(codeDevise, forKey: keyDevise)
        }
    }
    
    var symboleDevise: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = codeDevise
        return f.currencySymbol ?? codeDevise
    }
    
    private init() {
        self.codeDevise = UserDefaults.standard.string(forKey: "app.devise_code") ?? "EUR"
    }
    
    static let devisesDisponibles = [
        ("EUR", "Euro (€)"),
        ("CHF", "Franc Suisse (CHF)"),
        ("USD", "Dollar US ($)"),
        ("GBP", "Livre (£)"),
        ("CAD", "Dollar CA ($)"),
        ("JPY", "Yen (¥)")
    ]
}
