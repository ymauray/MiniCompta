import XCTest
import SwiftData
@testable import MiniCompta

final class BatchDeleteTests: XCTestCase {
    var container: ModelContainer!
    var context: ModelContext!
    var store: ParametresStore!

    @MainActor
    override func setUp() async throws {
        let schema = Schema([Ecriture.self, CentreDeCout.self, Categorie.self, TypeTVA.self])
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        container = try ModelContainer(for: schema, configurations: [config])
        context = container.mainContext
        store = ParametresStore(modelContext: context)
    }

    @MainActor
    func testReinitialisationAvecRelationsNePlantePas() async throws {
        // 1. Créer des données avec des relations
        let cat = Categorie(nom: "Test Cat")
        let centre = CentreDeCout(nom: "Test Centre")
        context.insert(cat)
        context.insert(centre)
        
        let ecriture = Ecriture(
            libelle: "Test",
            montantTTC: 100,
            tauxTVA: 0.2,
            typeTVANom: "Normal",
            centreDeCout: centre,
            categorie: cat
        )
        context.insert(ecriture)
        try context.save()
        
        // Vérifier que les relations sont bien établies
        XCTAssertNotNil(ecriture.categorie)
        XCTAssertNotNil(ecriture.centreDeCout)
        
        // 2. Tenter la réinitialisation (qui utilise effacerTout)
        // Si le bug est présent, cela lèvera une exception ou déclenchera une erreur Core Data
        do {
            try await store.reinitialiserToutesLesDonnees()
        } catch {
            XCTFail("La réinitialisation a échoué avec l'erreur : \(error)")
        }
        
        // 3. Vérifier que tout est effacé (sauf le seed de base)
        let fetchEcritures = FetchDescriptor<Ecriture>()
        let nbEcritures = try context.fetchCount(fetchEcritures)
        XCTAssertEqual(nbEcritures, 0, "Il ne devrait plus y avoir d'écritures")
        
        let fetchCats = FetchDescriptor<Categorie>()
        let nbCats = try context.fetchCount(fetchCats)
        XCTAssertEqual(nbCats, 0, "Il ne devrait plus y avoir de catégories")
    }
}
