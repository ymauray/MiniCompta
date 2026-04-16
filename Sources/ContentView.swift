import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var splashVisible = true

    var body: some View {
        ZStack {
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

            if splashVisible {
                SplashView()
                    .transition(.opacity)
                    .ignoresSafeArea()
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeInOut(duration: 0.4)) {
                splashVisible = false
            }
        }
    }
}
