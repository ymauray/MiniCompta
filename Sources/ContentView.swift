import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var splashVisible = true
    @State private var selection = 1

    var body: some View {
        ZStack {
            TabView(selection: $selection) {
                Tab("Tableau de bord", systemImage: "chart.pie.fill", value: 0) {
                    TableauDeBordView()
                }
                Tab("Journal", systemImage: "list.bullet.rectangle.fill", value: 1) {
                    JournalView()
                }
                Tab("Paramètres", systemImage: "gearshape.fill", value: 2) {
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
