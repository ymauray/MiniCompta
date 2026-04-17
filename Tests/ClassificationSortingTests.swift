import XCTest
import Foundation
import SwiftData
@testable import MiniCompta

@MainActor
final class ClassificationSortingTests: XCTestCase {

    func testCentresDeCoutDoiventEtreTriesParOrdre() async throws {
        // Given
        let context = try createModelContext()
        let store = ParametresStore(modelContext: context)
        
        let c1 = CentreDeCout(nom: "Z - Dernier", couleurHex: "#000000", ordre: 2)
        let c2 = CentreDeCout(nom: "A - Premier", couleurHex: "#000000", ordre: 0)
        let c3 = CentreDeCout(nom: "M - Milieu", couleurHex: "#000000", ordre: 1)
        
        context.insert(c1)
        context.insert(c2)
        context.insert(c3)
        try context.save()
        
        // When
        let resultats = store.centresDeCout()
        
        // Then
        XCTAssertEqual(resultats.count, 3)
        XCTAssertEqual(resultats[0].nom, "A - Premier")
        XCTAssertEqual(resultats[1].nom, "M - Milieu")
        XCTAssertEqual(resultats[2].nom, "Z - Dernier")
    }
    
    func testCategoriesDoiventEtreTriesParOrdre() async throws {
        // Given
        let context = try createModelContext()
        let store = ParametresStore(modelContext: context)
        
        let c1 = Categorie(nom: "Z - Dernier", couleurHex: "#000000", ordre: 2)
        let c2 = Categorie(nom: "A - Premier", couleurHex: "#000000", ordre: 0)
        let c3 = Categorie(nom: "M - Milieu", couleurHex: "#000000", ordre: 1)
        
        context.insert(c1)
        context.insert(c2)
        context.insert(c3)
        try context.save()
        
        // When
        let resultats = store.categories()
        
        // Then
        XCTAssertEqual(resultats.count, 3)
        XCTAssertEqual(resultats[0].nom, "A - Premier")
        XCTAssertEqual(resultats[1].nom, "M - Milieu")
        XCTAssertEqual(resultats[2].nom, "Z - Dernier")
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
