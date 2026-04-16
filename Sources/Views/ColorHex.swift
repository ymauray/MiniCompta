import SwiftUI
import Observation

extension Color {
    init(hex: String) {
        let h = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: h).scanHexInt64(&int)
        let r, g, b: Double
        switch h.count {
        case 6:
            r = Double((int >> 16) & 0xFF) / 255
            g = Double((int >> 8) & 0xFF) / 255
            b = Double(int & 0xFF) / 255
        default:
            r = 1; g = 1; b = 1
        }
        self.init(red: r, green: g, blue: b)
    }

    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return "#888888"
        }
        let r = Int(components[0] * 255)
        let g = Int(components[1] * 255)
        let b = Int(components[2] * 255)
        return String(format: "#%02X%02X%02X", r, g, b)
    }
}

@MainActor
extension Double {
    var formatMonetaire: String {
        let f = NumberFormatter()
        f.numberStyle = .currency
        f.currencyCode = DeviseStore.shared.codeDevise
        f.locale = Locale.current // Utilise la locale de l'appareil (format séparateurs, décimales)
        return f.string(from: NSNumber(value: self)) ?? "\(DeviseStore.shared.codeDevise) \(self)"
    }
}
