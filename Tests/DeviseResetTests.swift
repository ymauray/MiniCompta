import XCTest
import Foundation
import SwiftData
@testable import MiniCompta

@MainActor
final class DeviseResetTests: XCTestCase {

    func testReinitialisationRemetDeviseAEuro() async throws {
        // Given
        let store = DeviseStore.shared
        store.codeDevise = "USD"
        XCTAssertEqual(store.codeDevise, "USD")
        
        // When
        let parametresStore = ParametresStore(modelContext: try createModelContext())
        try await parametresStore.reinitialiserToutesLesDonnees()
        
        // Then
        XCTAssertEqual(store.codeDevise, "EUR", "La devise devrait être réinitialisée à EUR après un reset complet")
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
