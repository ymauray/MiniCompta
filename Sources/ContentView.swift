import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var splashVisible = true
    @State private var selection = 1
    @State private var afficherAlerteDemo = false

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
        .alert("Données de démonstration", isPresented: $afficherAlerteDemo) {
            Button("D'accord", role: .cancel) { }
        } message: {
            Text("Des données de démonstration ont été insérées automatiquement.\n\nVous pouvez les supprimer ou réinitialiser l'application dans les paramètres.")
        }
        .task {
            // Vérifie si on doit afficher l'alerte démo (flag injecté par ParametresStore)
            if UserDefaults.standard.bool(forKey: "app.doit_afficher_message_demo") {
                afficherAlerteDemo = true
                UserDefaults.standard.set(false, forKey: "app.doit_afficher_message_demo")
            }

            try? await Task.sleep(for: .seconds(2))
            withAnimation(.easeInOut(duration: 0.4)) {
                splashVisible = false
            }
        }
    }
}
