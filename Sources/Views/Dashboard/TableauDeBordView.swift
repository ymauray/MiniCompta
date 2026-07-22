import SwiftUI
import SwiftData
import Charts

struct TableauDeBordView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Ecriture.date, order: .reverse) private var ecritures: [Ecriture]
    @Query(sort: \CentreDeCout.ordre) private var tousLesCentres: [CentreDeCout]
    @Query(sort: \TypeTVA.ordre) private var tousLesTypesTVA: [TypeTVA]

    @State private var granularite: Granularite = .mois
    @State private var dateReference: Date = .now

    @State private var pdfAPartager: URL?
    @State private var afficherPartagePDF = false
    @State private var generationPDFEnCours = false

    enum Granularite: Equatable {
        case mois, trimestre, annee, tout
    }

    enum Raccourci: String, CaseIterable, Identifiable {
        case moisCourant = "Mois courant"
        case dernierTrimestre = "Dernier trim."
        case anneeEnCours = "Année en cours"
        case anneePrecedente = "Année préc."
        case tout = "Tout"
        var id: String { rawValue }
    }

    // MARK: - Période

    /// Bornes de la période affichée, en intervalle semi-ouvert [début, fin[.
    private var bornes: (debut: Date, finExclue: Date) {
        let cal = Calendar.current
        switch granularite {
        case .mois:
            let debut = cal.dateInterval(of: .month, for: dateReference)?.start ?? dateReference
            return (debut, cal.date(byAdding: .month, value: 1, to: debut) ?? dateReference)
        case .trimestre:
            let debut = debutTrimestre(pour: dateReference)
            return (debut, cal.date(byAdding: .month, value: 3, to: debut) ?? dateReference)
        case .annee:
            let debut = cal.dateInterval(of: .year, for: dateReference)?.start ?? dateReference
            return (debut, cal.date(byAdding: .year, value: 1, to: debut) ?? dateReference)
        case .tout:
            return (.distantPast, .distantFuture)
        }
    }

    private func debutTrimestre(pour date: Date) -> Date {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: date)
        let mois = comps.month ?? 1
        let premierMois = ((mois - 1) / 3) * 3 + 1
        return cal.date(from: DateComponents(year: comps.year, month: premierMois, day: 1)) ?? date
    }

    /// Vrai tant que la période affichée est entièrement passée (permet d'avancer).
    private var peutAvancer: Bool {
        bornes.finExclue <= .now
    }

    private func decaler(_ sens: Int) {
        let cal = Calendar.current
        let nouvelle: Date?
        switch granularite {
        case .mois: nouvelle = cal.date(byAdding: .month, value: sens, to: dateReference)
        case .trimestre: nouvelle = cal.date(byAdding: .month, value: sens * 3, to: dateReference)
        case .annee: nouvelle = cal.date(byAdding: .year, value: sens, to: dateReference)
        case .tout: nouvelle = dateReference
        }
        dateReference = nouvelle ?? dateReference
    }

    private func appliquer(_ raccourci: Raccourci) {
        let cal = Calendar.current
        switch raccourci {
        case .moisCourant:
            granularite = .mois
            dateReference = .now
        case .dernierTrimestre:
            granularite = .trimestre
            // Une date dans le trimestre précédent = la veille du début du trimestre courant.
            dateReference = cal.date(byAdding: .day, value: -1, to: debutTrimestre(pour: .now)) ?? .now
        case .anneeEnCours:
            granularite = .annee
            dateReference = .now
        case .anneePrecedente:
            granularite = .annee
            dateReference = cal.date(byAdding: .year, value: -1, to: .now) ?? .now
        case .tout:
            granularite = .tout
        }
    }

    private func estActif(_ raccourci: Raccourci) -> Bool {
        let cal = Calendar.current
        switch raccourci {
        case .moisCourant:
            return granularite == .mois && cal.isDate(dateReference, equalTo: .now, toGranularity: .month)
        case .dernierTrimestre:
            guard granularite == .trimestre else { return false }
            let veille = cal.date(byAdding: .day, value: -1, to: debutTrimestre(pour: .now)) ?? .now
            return debutTrimestre(pour: dateReference) == debutTrimestre(pour: veille)
        case .anneeEnCours:
            return granularite == .annee && cal.isDate(dateReference, equalTo: .now, toGranularity: .year)
        case .anneePrecedente:
            guard granularite == .annee else { return false }
            return cal.component(.year, from: dateReference) == cal.component(.year, from: .now) - 1
        case .tout:
            return granularite == .tout
        }
    }

    private var libellePeriode: String {
        let cal = Calendar.current
        switch granularite {
        case .mois:
            return dateReference.formatted(.dateTime.month(.wide).year())
        case .trimestre:
            let mois = cal.component(.month, from: debutTrimestre(pour: dateReference))
            let trimestre = (mois - 1) / 3 + 1
            let annee = cal.component(.year, from: dateReference)
            return "T\(trimestre) \(annee)"
        case .annee:
            return dateReference.formatted(.dateTime.year())
        case .tout:
            return "Toutes les écritures"
        }
    }

    /// Sous-titre décrivant la période exportée dans le PDF.
    private var sousTitrePeriode: String {
        if granularite == .tout {
            return "Toutes les écritures"
        }
        let formatter = DateFormatter()
        formatter.locale = .autoupdatingCurrent
        formatter.dateStyle = .long
        let finInclusive = Calendar.current.date(byAdding: .day, value: -1, to: bornes.finExclue) ?? bornes.finExclue
        return "Du \(formatter.string(from: bornes.debut)) au \(formatter.string(from: finInclusive))"
    }

    private func exporterPDF() {
        generationPDFEnCours = true
        let lignes = ecrituresPeriode
        let sousTitre = sousTitrePeriode
        let centres = tousLesCentres
        let tvas = tousLesTypesTVA
        Task {
            let url = GenerateurPDF.generer(ecritures: lignes, sousTitre: sousTitre, centres: centres, typesTVA: tvas)
            await MainActor.run {
                pdfAPartager = url
                afficherPartagePDF = url != nil
                generationPDFEnCours = false
            }
        }
    }

    // MARK: - Totaux

    private var ecrituresPeriode: [Ecriture] {
        let (debut, finExclue) = bornes
        return ecritures.filter { $0.date >= debut && $0.date < finExclue }
    }

    private var totalRecettes: Double {
        ecrituresPeriode.filter { $0.typeEcriture == .recette }.reduce(0) { $0 + $1.montantTTC }
    }

    private var totalDepenses: Double {
        ecrituresPeriode.filter { $0.typeEcriture == .depense }.reduce(0) { $0 + $1.montantTTC }
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
        for e in ecrituresPeriode {
            if e.centresDeCout.isEmpty {
                dict["Autres", default: ("#AAAAAA", 0)].total += e.montantTTC
            } else {
                // Montant compté en entier pour chaque centre affecté
                for centre in e.centresDeCout {
                    dict[centre.nom, default: (centre.couleurHex, 0)].total += e.montantTTC
                }
            }
        }
        return dict.map { Segment(nom: $0.key, couleurHex: $0.value.couleur, montant: $0.value.total) }
            .sorted { $0.montant > $1.montant }
    }

    private var parCategorie: [Segment] {
        var dict: [String: (couleur: String, total: Double)] = [:]
        for e in ecrituresPeriode {
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
                    selecteurPeriode
                    cartesSommaire
                    if !ecrituresPeriode.isEmpty {
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
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        exporterPDF()
                    } label: {
                        if generationPDFEnCours {
                            ProgressView()
                        } else {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                    .disabled(ecrituresPeriode.isEmpty || generationPDFEnCours)
                }
            }
            .sheet(isPresented: $afficherPartagePDF) {
                if let url = pdfAPartager {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    // MARK: - Sous-vues

    private var selecteurPeriode: some View {
        VStack(spacing: 12) {
            FlowLayout(spacing: 8) {
                ForEach(Raccourci.allCases) { raccourci in
                    Button(raccourci.rawValue) {
                        appliquer(raccourci)
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .tint(estActif(raccourci) ? .accentColor : .secondary)
                }
            }

            HStack {
                Button {
                    decaler(-1)
                } label: {
                    Image(systemName: "chevron.left")
                        .padding(8)
                }
                .buttonStyle(.bordered)
                .disabled(granularite == .tout)

                Spacer()

                Text(libellePeriode)
                    .font(.headline)
                    .textCase(.uppercase)

                Spacer()

                Button {
                    decaler(1)
                } label: {
                    Image(systemName: "chevron.right")
                        .padding(8)
                }
                .buttonStyle(.bordered)
                .disabled(!peutAvancer)
            }
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
            Text("Aucune écriture sur cette période")
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
