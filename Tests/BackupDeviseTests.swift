import XCTest
import Foundation
import SwiftData
@testable import MiniCompta

@MainActor
final class BackupDeviseTests: XCTestCase {

    func testExportImportDoitConserverLaDevise() async throws {
        // Given
        let store = DeviseStore.shared
        store.codeDevise = "CHF"
        XCTAssertEqual(store.codeDevise, "CHF")
        
        let parametresStore = ParametresStore(modelContext: try createModelContext())
        
        // When
        guard let url = parametresStore.exporterDonnees() else {
            XCTFail("L'export a échoué")
            return
        }
        
        // On change la devise après l'export
        store.codeDevise = "USD"
        XCTAssertEqual(store.codeDevise, "USD")
        
        // On réimporte
        try await parametresStore.importerDonnees(depuis: url)
        
        // Then
        XCTAssertEqual(store.codeDevise, "CHF", "La devise devrait être restaurée à CHF après l'import")
        
        // Nettoyage
        try? FileManager.default.removeItem(at: url)
    }
    
    private func createModelContext() throws -> ModelContext {
        let schema = Schema([
            Ecriture.self,
            Categorie.self,
            CentreDeCout.self,
            TypeTVA.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
        return ModelContext(container)
    }
}
