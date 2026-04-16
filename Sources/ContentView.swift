import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    var body: some View {
        TabView {
            Tab("Tableau de bord", systemImage: "chart.pie.fill") {
                TableauDeBordView()
            }
            Tab("Journal", systemImage: "list.bullet.rectangle.fill") {
                JournalView()
            }
            Tab("Paramètres", systemImage: "gearshape.fill") {
                ParametresView()
            }
        }
        .tint(.accentColor)
    }
}
