import SwiftUI
import SwiftData
import Charts

struct TableauDeBordView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Ecriture.date, order: .reverse) private var ecritures: [Ecriture]

    @State private var moisAffiche: Date = .now

    // MARK: - Totaux

    private var ecrituresDuMois: [Ecriture] {
        let cal = Calendar.current
        return ecritures.filter {
            cal.isDate($0.date, equalTo: moisAffiche, toGranularity: .month)
        }
    }

    private var totalRecettes: Double {
        ecrituresDuMois.filter { $0.typeEcriture == .recette }.reduce(0) { $0 + $1.montantTTC }
    }

    private var totalDepenses: Double {
        ecrituresDuMois.filter { $0.typeEcriture == .depense }.reduce(0) { $0 + $1.montantTTC }
    }

    private var solde: Double { totalRecettes - totalDepenses }

    // MARK: - Agrégats

    struct Segment: Identifiable {
        let id = UUID()
        let nom: String
        let couleurHex: String
        let montant: Double
    }

    private var parCentre: [Segment] {
        var dict: [String: (couleur: String, total: Double)] = [:]
        for e in ecrituresDuMois {
            let nom = e.centreDeCout?.nom ?? "Autres"
            let couleur = e.centreDeCout?.couleurHex ?? "#AAAAAA"
            dict[nom, default: (couleur, 0)].total += e.montantTTC
        }
        return dict.map { Segment(nom: $0.key, couleurHex: $0.value.couleur, montant: $0.value.total) }
            .sorted { $0.montant > $1.montant }
    }

    private var parCategorie: [Segment] {
        var dict: [String: (couleur: String, total: Double)] = [:]
        for e in ecrituresDuMois {
            let nom = e.categorie?.nom ?? "Autres"
            let couleur = e.categorie?.couleurHex ?? "#AAAAAA"
            dict[nom, default: (couleur, 0)].total += e.montantTTC
        }
        return dict.map { Segment(nom: $0.key, couleurHex: $0.value.couleur, montant: $0.value.total) }
            .sorted { $0.montant > $1.montant }
    }

    private var dernieresEcritures: [Ecriture] {
        Array(ecritures.prefix(5))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    selecteurMois
                    cartesSommaire
                    if !ecrituresDuMois.isEmpty {
                        if parCentre.count > 1 {
                            graphiqueCentres
                        }
                        if parCategorie.count > 1 {
                            graphiqueCategories
                        }
                        dernieresEcrituresSection
                    } else {
                        etatVideMois
                    }
                }
                .padding()
            }
            .navigationTitle("Tableau de bord")
            .background(Color(.systemGroupedBackground))
        }
    }

    // MARK: - Sous-vues

    private var selecteurMois: some View {
        HStack {
            Button {
                moisAffiche = Calendar.current.date(byAdding: .month, value: -1, to: moisAffiche) ?? moisAffiche
            } label: {
                Image(systemName: "chevron.left")
                    .padding(8)
            }
            .buttonStyle(.bordered)

            Spacer()

            Text(moisAffiche, format: .dateTime.month(.wide).year())
                .font(.headline)
                .textCase(.uppercase)

            Spacer()

            Button {
                moisAffiche = Calendar.current.date(byAdding: .month, value: 1, to: moisAffiche) ?? moisAffiche
            } label: {
                Image(systemName: "chevron.right")
                    .padding(8)
            }
            .buttonStyle(.bordered)
            .disabled(Calendar.current.isDate(moisAffiche, equalTo: .now, toGranularity: .month))
        }
    }

    private var cartesSommaire: some View {
        HStack(spacing: 12) {
            CarteTotaux(titre: "Recettes", montant: totalRecettes, couleur: .green, icone: "arrow.down.circle.fill")
            CarteTotaux(titre: "Dépenses", montant: totalDepenses, couleur: .red, icone: "arrow.up.circle.fill")
            CarteTotaux(
                titre: "Solde",
                montant: abs(solde),
                couleur: solde >= 0 ? .green : .red,
                icone: solde >= 0 ? "plus.circle.fill" : "minus.circle.fill",
                signe: solde >= 0 ? "+" : "-"
            )
        }
    }

    private var graphiqueCentres: some View {
        CarteGraphique(titre: "Par centre de coût") {
            Chart(parCentre) { s in
                BarMark(
                    x: .value("Montant", s.montant),
                    y: .value("Centre", s.nom)
                )
                .foregroundStyle(Color(hex: s.couleurHex))
                .cornerRadius(4)
            }
            .chartXAxis {
                let maxMontant = parCentre.map(\.montant).max() ?? 0
                AxisMarks { value in
                    AxisGridLine()
                    if let d = value.as(Double.self), d > 0 && d < maxMontant * 0.9 {
                        AxisValueLabel {
                            Text(d.formatMonetaire).font(.caption2)
                        }
                    }
                }
            }
            .frame(height: CGFloat(max(120, parCentre.count * 44)))
        }
    }

    private var graphiqueCategories: some View {
        CarteGraphique(titre: "Par catégorie") {
            Chart(parCategorie) { s in
                SectorMark(
                    angle: .value("Montant", s.montant),
                    innerRadius: .ratio(0.55),
                    angularInset: 2
                )
                .foregroundStyle(Color(hex: s.couleurHex))
                .cornerRadius(4)
                .annotation(position: .overlay) {
                    let total = parCategorie.reduce(0) { $0 + $1.montant }
                    if total > 0 && s.montant / total > 0.08 {
                        Text(s.nom)
                            .font(.system(size: 9, weight: .bold))
                            .foregroundStyle(.white)
                            .lineLimit(1)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background {
                                Capsule()
                                    .fill(.black.opacity(0.35))
                                    .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                            }
                    }
                }
            }
            .frame(height: 200)

            legendeCategories
        }
    }

    private var legendeCategories: some View {
        let total = parCategorie.reduce(0) { $0 + $1.montant }
        return FlowLayout(spacing: 8) {
            ForEach(parCategorie) { s in
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: s.couleurHex))
                        .frame(width: 8, height: 8)
                    Text(s.nom)
                        .font(.caption2)
                    if total > 0 {
                        Text(String(format: "%.0f%%", s.montant / total * 100))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    private var dernieresEcrituresSection: some View {
        CarteGraphique(titre: "Dernières écritures") {
            VStack(spacing: 0) {
                ForEach(dernieresEcritures) { e in
                    LigneEcriture(ecriture: e)
                    if e.id != dernieresEcritures.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private var etatVideMois: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundStyle(.secondary)
            Text("Aucune écriture ce mois-ci")
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Carte totaux

struct CarteTotaux: View {
    let titre: String
    let montant: Double
    let couleur: Color
    let icone: String
    var signe: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icone)
                    .foregroundStyle(couleur)
                Spacer()
            }
            Text(titre)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text("\(signe)\(montant.formatMonetaire)")
                .font(.callout.bold())
                .foregroundStyle(couleur)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
        .padding(12)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.06), radius: 4, x: 0, y: 2)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Carte graphique

struct CarteGraphique<Contenu: View>: View {
    let titre: String
    @ViewBuilder let contenu: () -> Contenu

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(titre)
                .font(.headline)
            contenu()
        }
        .padding(16)
        .background(.background)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 2)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - FlowLayout (légende)

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let largeur = proposal.width ?? 300
        var x: CGFloat = 0
        var y: CGFloat = 0
        var hauteurLigne: CGFloat = 0

        for sv in subviews {
            let taille = sv.sizeThatFits(.unspecified)
            if x + taille.width > largeur && x > 0 {
                x = 0
                y += hauteurLigne + spacing
                hauteurLigne = 0
            }
            x += taille.width + spacing
            hauteurLigne = max(hauteurLigne, taille.height)
        }
        return CGSize(width: largeur, height: y + hauteurLigne)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var hauteurLigne: CGFloat = 0

        for sv in subviews {
            let taille = sv.sizeThatFits(.unspecified)
            if x + taille.width > bounds.maxX && x > bounds.minX {
                x = bounds.minX
                y += hauteurLigne + spacing
                hauteurLigne = 0
            }
            sv.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(taille))
            x += taille.width + spacing
            hauteurLigne = max(hauteurLigne, taille.height)
        }
    }
}
