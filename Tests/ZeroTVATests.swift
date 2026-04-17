import XCTest
import Foundation
import SwiftData
@testable import MiniCompta

@MainActor
final class ZeroTVATests: XCTestCase {

    func testEcritureAvecTVAZeroConserveLeNomDuType() async throws {
        // Given
        let context = try createModelContext()
        
        let typeTVAZero = TypeTVA(nom: "Exonéré 0%", taux: 0.0, signification: "Test", ordre: 0)
        context.insert(typeTVAZero)
        
        let ecriture = Ecriture(
            date: .now,
            libelle: "Test TVA 0%",
            typeEcriture: .depense,
            montantTTC: 100,
            tauxTVA: 0.0,
            typeTVANom: "Exonéré 0%"
        )
        context.insert(ecriture)
        try context.save()
        
        // When
        let fetch = FetchDescriptor<Ecriture>()
        let resultats = try context.fetch(fetch)
        
        // Then
        XCTAssertEqual(resultats.count, 1)
        XCTAssertEqual(resultats[0].typeTVANom, "Exonéré 0%")
        XCTAssertEqual(resultats[0].tauxTVA, 0.0)
        XCTAssertEqual(resultats[0].montantTVA, 0.0)
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
