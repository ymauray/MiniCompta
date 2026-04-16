import SwiftData
import Foundation

enum TypeEcriture: String, Codable, CaseIterable {
    case depense = "depense"
    case recette = "recette"

    var label: String {
        switch self {
        case .depense: return "Dépense"
        case .recette: return "Recette"
        }
    }
}

@Model
final class Ecriture {
    var date: Date
    var libelle: String
    var typeEcriture: TypeEcriture
    var montantTTC: Double
    var tauxTVA: Double

    var centreDeCout: CentreDeCout?
    var categorie: Categorie?

    // TypeTVA est stocké par nom/taux pour éviter une dépendance forte
    var typeTVANom: String

    init(
        date: Date = .now,
        libelle: String = "",
        typeEcriture: TypeEcriture = .depense,
        montantTTC: Double = 0,
        tauxTVA: Double = 0.20,
        typeTVANom: String = "",
        centreDeCout: CentreDeCout? = nil,
        categorie: Categorie? = nil
    ) {
        self.date = date
        self.libelle = libelle
        self.typeEcriture = typeEcriture
        self.montantTTC = montantTTC
        self.tauxTVA = tauxTVA
        self.typeTVANom = typeTVANom
        self.centreDeCout = centreDeCout
        self.categorie = categorie
    }

    var montantHT: Double {
        montantTTC / (1 + tauxTVA)
    }

    var montantTVA: Double {
        montantTTC - montantHT
    }

    /// Montant signé : positif pour recette, négatif pour dépense
    var montantSigne: Double {
        typeEcriture == .recette ? montantTTC : -montantTTC
    }
}
