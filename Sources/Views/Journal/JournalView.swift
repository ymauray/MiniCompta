import SwiftUI
import SwiftData

struct JournalView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Ecriture.date, order: .reverse) private var ecritures: [Ecriture]

    @State private var afficherFormulaire = false
    @State private var ecritureAModifier: Ecriture?
    @State private var recherche = ""

    private var ecrituresFiltrees: [Ecriture] {
        guard !recherche.isEmpty else { return ecritures }
        return ecritures.filter { $0.libelle.localizedCaseInsensitiveContains(recherche) }
    }

    private var groupesParMois: [(cle: String, ecritures: [Ecriture])] {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "fr_CH")
        formatter.dateFormat = "MMMM yyyy"

        var groupes: [(cle: String, ecritures: [Ecriture])] = []
        var clesVues: [String] = []

        for e in ecrituresFiltrees {
            let cle = formatter.string(from: e.date).capitalized
            if !clesVues.contains(cle) {
                clesVues.append(cle)
                groupes.append((cle: cle, ecritures: []))
            }
            if let idx = groupes.firstIndex(where: { $0.cle == cle }) {
                groupes[idx].ecritures.append(e)
            }
        }
        return groupes
    }

    var body: some View {
        NavigationStack {
            Group {
                if ecritures.isEmpty {
                    etatVide
                } else {
                    listePrincipale
                }
            }
            .navigationTitle("Journal")
            .searchable(text: $recherche, prompt: "Rechercher un libellé")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        ecritureAModifier = nil
                        afficherFormulaire = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                    }
                }
            }
            .sheet(isPresented: $afficherFormulaire) {
                EcritureFormView()
            }
            .sheet(item: $ecritureAModifier) { e in
                EcritureFormView(ecritureExistante: e)
            }
        }
    }

    // MARK: - Sous-vues

    private var etatVide: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 60))
                .foregroundStyle(.secondary)
            Text("Aucune écriture")
                .font(.title2.bold())
            Text("Appuyez sur + pour ajouter\nvotre première écriture.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            Button {
                afficherFormulaire = true
            } label: {
                Label("Ajouter une écriture", systemImage: "plus")
                    .padding(.horizontal)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }

    private var listePrincipale: some View {
        List {
            ForEach(groupesParMois, id: \.cle) { groupe in
                Section(header: enteteSection(groupe)) {
                    ForEach(groupe.ecritures) { ecriture in
                        LigneEcriture(ecriture: ecriture)
                            .contentShape(Rectangle())
                            .onTapGesture { ecritureAModifier = ecriture }
                    }
                    .onDelete { offsets in
                        supprimer(offsets, dans: groupe.ecritures)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private func enteteSection(_ groupe: (cle: String, ecritures: [Ecriture])) -> some View {
        let totalDepenses = groupe.ecritures.filter { $0.typeEcriture == .depense }.reduce(0) { $0 + $1.montantTTC }
        let totalRecettes = groupe.ecritures.filter { $0.typeEcriture == .recette }.reduce(0) { $0 + $1.montantTTC }
        return HStack {
            Text(groupe.cle)
            Spacer()
            if totalRecettes > 0 {
                Text("+\(totalRecettes.formatMonetaire)")
                    .foregroundStyle(.green)
                    .font(.caption.bold())
            }
            if totalDepenses > 0 {
                Text("-\(totalDepenses.formatMonetaire)")
                    .foregroundStyle(.red)
                    .font(.caption.bold())
            }
        }
    }

    private func supprimer(_ offsets: IndexSet, dans liste: [Ecriture]) {
        for i in offsets {
            modelContext.delete(liste[i])
        }
        try? modelContext.save()
    }
}

// MARK: - Ligne d'écriture

struct LigneEcriture: View {
    let ecriture: Ecriture

    private var couleurMontant: Color {
        ecriture.typeEcriture == .recette ? .green : .red
    }

    private var iconType: String {
        ecriture.typeEcriture == .recette ? "arrow.down.circle.fill" : "arrow.up.circle.fill"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: iconType)
                .font(.title2)
                .foregroundStyle(couleurMontant)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 3) {
                Text(ecriture.libelle.isEmpty ? "Sans libellé" : ecriture.libelle)
                    .font(.body)
                    .lineLimit(1)
                HStack(spacing: 6) {
                    Text(ecriture.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    if let cat = ecriture.categorie {
                        BadgeView(texte: cat.nom, couleurHex: cat.couleurHex)
                    }
                    if let centre = ecriture.centreDeCout {
                        BadgeView(texte: centre.nom, couleurHex: centre.couleurHex)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text("\(ecriture.typeEcriture == .recette ? "+" : "-")\(ecriture.montantTTC.formatMonetaire)")
                    .font(.body.bold())
                    .foregroundStyle(couleurMontant)
                if ecriture.tauxTVA > 0 {
                    Text("TVA \(ecriture.typeTVANom)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Badge

struct BadgeView: View {
    let texte: String
    let couleurHex: String

    var body: some View {
        Text(texte)
            .font(.caption2.bold())
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color(hex: couleurHex).opacity(0.2))
            .foregroundStyle(Color(hex: couleurHex))
            .clipShape(Capsule())
    }
}
