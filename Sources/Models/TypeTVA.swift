import SwiftData
import Foundation

@Model
final class TypeTVA {
    var nom: String
    var taux: Double
    var signification: String
    var caseFormulaire: String
    var ordre: Int

    init(nom: String, taux: Double, signification: String, caseFormulaire: String = "", ordre: Int = 0) {
        self.nom = nom
        self.taux = taux
        self.signification = signification
        self.caseFormulaire = caseFormulaire
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
            TypeTVA(nom: "Normal 8.1%", taux: 0.081, signification: "Taux normal", caseFormulaire: "302", ordre: 0),
            TypeTVA(nom: "Spécial 2.6%", taux: 0.026, signification: "Hôtellerie / presse", caseFormulaire: "342", ordre: 1),
            TypeTVA(nom: "Exonéré 0%", taux: 0.0, signification: "Opérations hors TVA", caseFormulaire: "", ordre: 2),
        ]
    }
}
