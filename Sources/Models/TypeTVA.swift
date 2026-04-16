import SwiftData
import Foundation

@Model
final class TypeTVA {
    var nom: String
    var taux: Double
    var signification: String
    var ordre: Int

    init(nom: String, taux: Double, signification: String, ordre: Int = 0) {
        self.nom = nom
        self.taux = taux
        self.signification = signification
        self.ordre = ordre
    }

    var tauxFormate: String {
        let pct = taux * 100
        if pct == pct.rounded() {
            return "\(Int(pct))%"
        }
        return String(format: "%.1f%%", pct)
    }

    static var seedData: [TypeTVA] {
        [
            TypeTVA(nom: "Normal 20%", taux: 0.20, signification: "Taux normal", ordre: 0),
            TypeTVA(nom: "Réduit 5.5%", taux: 0.055, signification: "Taux réduit", ordre: 1),
            TypeTVA(nom: "Exonéré 0%", taux: 0.0, signification: "Opérations hors TVA", ordre: 2),
        ]
    }
}
