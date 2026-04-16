import SwiftData
import Foundation
import Observation

@Observable
final class JournalStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Lecture

    func ecritures(mois: Date? = nil) -> [Ecriture] {
        var descripteur = FetchDescriptor<Ecriture>(sortBy: [SortDescriptor(\.date, order: .reverse)])
        if let mois {
            let debut = mois.debutDeMois
            let fin = mois.finDeMois
            descripteur.predicate = #Predicate<Ecriture> { e in
                e.date >= debut && e.date <= fin
            }
        }
        return (try? modelContext.fetch(descripteur)) ?? []
    }

    func ecrituresGroupeesParMois() -> [(cle: String, ecritures: [Ecriture])] {
        let toutes = ecritures()
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_CH")
        formatter.dateFormat = "MMMM yyyy"

        var groupes: [(cle: String, ecritures: [Ecriture])] = []
        var clesVues: [String] = []

        for e in toutes {
            let cle = formatter.string(from: e.date).capitalized
            if !clesVues.contains(cle) {
                clesVues.append(cle)
                groupes.append((cle: cle, ecritures: []))
            }
            if let idx = groupes.firstIndex(where: { $0.cle == cle }) {
                groupes[idx].ecritures.append(e)
            }
        }
        return groupes
    }

    // MARK: - Totaux du mois courant

    func totalRecettesMois(_ mois: Date = .now) -> Double {
        ecritures(mois: mois)
            .filter { $0.typeEcriture == .recette }
            .reduce(0) { $0 + $1.montantTTC }
    }

    func totalDepensesMois(_ mois: Date = .now) -> Double {
        ecritures(mois: mois)
            .filter { $0.typeEcriture == .depense }
            .reduce(0) { $0 + $1.montantTTC }
    }

    func soldeMois(_ mois: Date = .now) -> Double {
        totalRecettesMois(mois) - totalDepensesMois(mois)
    }

    // MARK: - Agrégats pour graphiques

    struct TotalParGroupe: Identifiable {
        let id = UUID()
        let nom: String
        let couleurHex: String
        let montant: Double
    }

    func totauxParCentreDeCout(mois: Date = .now) -> [TotalParGroupe] {
        let liste = ecritures(mois: mois)
        var dict: [String: (couleur: String, total: Double)] = [:]
        for e in liste {
            let nom = e.centreDeCout?.nom ?? "Sans centre"
            let couleur = e.centreDeCout?.couleurHex ?? "#AAAAAA"
            let val = e.typeEcriture == .depense ? e.montantTTC : -e.montantTTC
            dict[nom, default: (couleur, 0)].total += val
        }
        return dict.map { TotalParGroupe(nom: $0.key, couleurHex: $0.value.couleur, montant: $0.value.total) }
            .sorted { $0.montant > $1.montant }
    }

    func totauxParCategorie(mois: Date = .now) -> [TotalParGroupe] {
        let liste = ecritures(mois: mois)
        var dict: [String: (couleur: String, total: Double)] = [:]
        for e in liste {
            let nom = e.categorie?.nom ?? "Sans catégorie"
            let couleur = e.categorie?.couleurHex ?? "#AAAAAA"
            let val = e.montantTTC
            dict[nom, default: (couleur, 0)].total += val
        }
        return dict.map { TotalParGroupe(nom: $0.key, couleurHex: $0.value.couleur, montant: $0.value.total) }
            .sorted { $0.montant > $1.montant }
    }

    // MARK: - Écriture

    func ajouterEcriture(_ ecriture: Ecriture) {
        modelContext.insert(ecriture)
        try? modelContext.save()
    }

    func supprimerEcriture(_ ecriture: Ecriture) {
        modelContext.delete(ecriture)
        try? modelContext.save()
    }

    func sauvegarder() {
        try? modelContext.save()
    }
}

// MARK: - Helpers Date

extension Date {
    var debutDeMois: Date {
        Calendar.current.dateInterval(of: .month, for: self)?.start ?? self
    }

    var finDeMois: Date {
        guard let intervalle = Calendar.current.dateInterval(of: .month, for: self) else { return self }
        return intervalle.end.addingTimeInterval(-1)
    }
}
