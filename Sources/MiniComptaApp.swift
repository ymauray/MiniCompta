import SwiftUI
import SwiftData

@main
struct MiniComptaApp: App {
    let container: ModelContainer

    init() {
        do {
            container = try ModelContainer(
                for: Ecriture.self, CentreDeCout.self, Categorie.self, TypeTVA.self
            )
            // Déclenche l'injection des données (types TVA et démo si nécessaire)
            _ = ParametresStore(modelContext: container.mainContext)
        } catch {
            fatalError("Impossible de créer le ModelContainer : \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}
