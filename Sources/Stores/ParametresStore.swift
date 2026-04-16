import SwiftData
import Foundation
import Observation

@Observable
final class ParametresStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        seedSiNecessaire()
    }

    // MARK: - Seed initial

    private func seedSiNecessaire() {
        let descripteur = FetchDescriptor<TypeTVA>()
        let count = (try? modelContext.fetchCount(descripteur)) ?? 0
        guard count == 0 else { return }
        for tva in TypeTVA.seedData {
            modelContext.insert(tva)
        }
        try? modelContext.save()
    }

    // MARK: - Types TVA

    func typesTVA() -> [TypeTVA] {
        let descripteur = FetchDescriptor<TypeTVA>(sortBy: [SortDescriptor(\.ordre)])
        return (try? modelContext.fetch(descripteur)) ?? []
    }

    func ajouterTypeTVA(nom: String, taux: Double, signification: String) {
        let t = TypeTVA(nom: nom, taux: taux, signification: signification)
        modelContext.insert(t)
        try? modelContext.save()
    }

    func supprimerTypeTVA(_ typeTVA: TypeTVA) {
        modelContext.delete(typeTVA)
        try? modelContext.save()
    }

    // MARK: - Centres de coût

    func centresDeCout() -> [CentreDeCout] {
        let descripteur = FetchDescriptor<CentreDeCout>(sortBy: [SortDescriptor(\.nom)])
        return (try? modelContext.fetch(descripteur)) ?? []
    }

    func ajouterCentreDeCout(nom: String, couleurHex: String) {
        let c = CentreDeCout(nom: nom, couleurHex: couleurHex)
        modelContext.insert(c)
        try? modelContext.save()
    }

    func supprimerCentreDeCout(_ centre: CentreDeCout) {
        modelContext.delete(centre)
        try? modelContext.save()
    }

    // MARK: - Catégories

    func categories() -> [Categorie] {
        let descripteur = FetchDescriptor<Categorie>(sortBy: [SortDescriptor(\.nom)])
        return (try? modelContext.fetch(descripteur)) ?? []
    }

    func ajouterCategorie(nom: String, couleurHex: String) {
        let c = Categorie(nom: nom, couleurHex: couleurHex)
        modelContext.insert(c)
        try? modelContext.save()
    }

    func supprimerCategorie(_ categorie: Categorie) {
        modelContext.delete(categorie)
        try? modelContext.save()
    }
}
