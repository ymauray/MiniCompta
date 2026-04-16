import SwiftUI
import SwiftData
import PDFKit

struct ExportPDFView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Ecriture.date, order: .reverse) private var ecritures: [Ecriture]

    @State private var dateDebut: Date = Calendar.current.date(byAdding: .month, value: -1, to: .now) ?? .now
    @State private var dateFin: Date = .now
    @State private var pdfAPartager: URL?
    @State private var afficherPartage = false
    @State private var generationEnCours = false

    private var ecrituresFiltrees: [Ecriture] {
        ecritures.filter { $0.date >= dateDebut && $0.date <= dateFin }
            .sorted { $0.date < $1.date }
    }

    private var totalRecettes: Double {
        ecrituresFiltrees.filter { $0.typeEcriture == .recette }.reduce(0) { $0 + $1.montantTTC }
    }

    private var totalDepenses: Double {
        ecrituresFiltrees.filter { $0.typeEcriture == .depense }.reduce(0) { $0 + $1.montantTTC }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Raccourcis") {
                    HStack(spacing: 8) {
                        Button("Dernier trim.") {
                            appliquerDernierTrimestre()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)

                        Button("Année en cours") {
                            appliquerAnneeEnCours()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)

                        Button("Année préc.") {
                            appliquerAnneePrecedente()
                        }
                        .buttonStyle(.bordered)
                        .font(.caption)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets())
                }

                Section("Période personnalisée") {
                    DatePicker("Du", selection: $dateDebut, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "fr_CH"))
                    DatePicker("Au", selection: $dateFin, in: dateDebut..., displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "fr_CH"))
                }

                Section("Aperçu") {
                    LabeledContent("Écritures sélectionnées") {
                        Text("\(ecrituresFiltrees.count)")
                    }
                    LabeledContent("Total recettes") {
                        Text(totalRecettes.formatMonetaire).foregroundStyle(.green)
                    }
                    LabeledContent("Total dépenses") {
                        Text(totalDepenses.formatMonetaire).foregroundStyle(.red)
                    }
                    LabeledContent("Solde") {
                        let solde = totalRecettes - totalDepenses
                        Text(solde.formatMonetaire)
                            .foregroundStyle(solde >= 0 ? .green : .red)
                    }
                }

                Section {
                    Button {
                        genererEtPartager()
                    } label: {
                        if generationEnCours {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 8)
                                Text("Génération en cours…")
                            }
                        } else {
                            Label("Générer et partager le PDF", systemImage: "doc.richtext")
                        }
                    }
                    .disabled(ecrituresFiltrees.isEmpty || generationEnCours)
                }
            }
            .navigationTitle("Export PDF")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $afficherPartage) {
                if let url = pdfAPartager {
                    ShareSheet(activityItems: [url])
                }
            }
        }
    }

    // MARK: - Actions de raccourci

    private func appliquerDernierTrimestre() {
        let cal = Calendar.current
        let m = cal.component(.month, from: .now)
        let y = cal.component(.year, from: .now)
        
        // Le trimestre est (m-1)/3 (0: JFM, 1: AMJ, 2: JAS, 3: OND)
        let trimestreActuel = (m - 1) / 3
        let tPrec = trimestreActuel == 0 ? 3 : trimestreActuel - 1
        let aPrec = trimestreActuel == 0 ? y - 1 : y
        
        let mDebut = tPrec * 3 + 1
        let mFin = mDebut + 2
        
        let componentsDebut = DateComponents(year: aPrec, month: mDebut, day: 1)
        if let d = cal.date(from: componentsDebut) {
            dateDebut = d
            // Dernier jour du mois mFin
            let componentsSuivant = DateComponents(year: aPrec, month: mFin + 1, day: 1)
            if let dSuivante = cal.date(from: componentsSuivant) {
                dateFin = cal.date(byAdding: .day, value: -1, to: dSuivante) ?? .now
            }
        }
    }

    private func appliquerAnneeEnCours() {
        let y = Calendar.current.component(.year, from: .now)
        let componentsDebut = DateComponents(year: y, month: 1, day: 1)
        let componentsFin = DateComponents(year: y, month: 12, day: 31)
        if let d = Calendar.current.date(from: componentsDebut), let f = Calendar.current.date(from: componentsFin) {
            dateDebut = d
            dateFin = f
        }
    }

    private func appliquerAnneePrecedente() {
        let y = Calendar.current.component(.year, from: .now) - 1
        let componentsDebut = DateComponents(year: y, month: 1, day: 1)
        let componentsFin = DateComponents(year: y, month: 12, day: 31)
        if let d = Calendar.current.date(from: componentsDebut), let f = Calendar.current.date(from: componentsFin) {
            dateDebut = d
            dateFin = f
        }
    }

    // MARK: - Génération PDF

    private func genererEtPartager() {
        generationEnCours = true
        Task {
            let url = genererPDF()
            await MainActor.run {
                pdfAPartager = url
                afficherPartage = url != nil
                generationEnCours = false
            }
        }
    }

    private func genererPDF() -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "fr_CH")
        dateFormatter.dateStyle = .short

        let pdfMeta = [
            kCGPDFContextCreator: "Mini Compta",
            kCGPDFContextAuthor: "Mini Compta"
        ]

        let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8)  // A4
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("journal_\(Int(Date().timeIntervalSince1970)).pdf")

        guard let context = CGContext(url as CFURL, mediaBox: nil, pdfMeta as CFDictionary) else { return nil }

        let margeH: CGFloat = 40
        let margeV: CGFloat = 50
        let largeurContenu = pageRect.width - 2 * margeH
        var y = pageRect.height - margeV

        func nouvellePageSiNecessaire(hauteurRequise: CGFloat) {
            if y - hauteurRequise < margeV {
                context.endPDFPage()
                context.beginPDFPage(nil)
                y = pageRect.height - margeV
                dessinerEntete()
            }
        }

        func dessinerEntete() {
            let titreAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.black
            ]
            let titre = NSAttributedString(string: "Journal comptable", attributes: titreAttrs)
            titre.draw(at: CGPoint(x: margeH, y: pageRect.height - margeV - 20))

            let sousAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.gray
            ]
            let periode = "Du \(dateFormatter.string(from: dateDebut)) au \(dateFormatter.string(from: dateFin))"
            let sous = NSAttributedString(string: periode, attributes: sousAttrs)
            sous.draw(at: CGPoint(x: margeH, y: pageRect.height - margeV - 38))

            y = pageRect.height - margeV - 60
        }

        context.beginPDFPage(nil)
        dessinerEntete()

        // En-tête tableau
        let colW: [CGFloat] = [70, 200, 90, 70, 90]
        let colX: [CGFloat] = [
            margeH,
            margeH + colW[0],
            margeH + colW[0] + colW[1],
            margeH + colW[0] + colW[1] + colW[2],
            margeH + colW[0] + colW[1] + colW[2] + colW[3]
        ]
        let entetes = ["Date", "Libellé", "Type", "TVA", "Montant TTC"]

        nouvellePageSiNecessaire(hauteurRequise: 30)
        context.setFillColor(UIColor.systemBlue.withAlphaComponent(0.15).cgColor)
        context.fill(CGRect(x: margeH, y: y - 20, width: largeurContenu, height: 20))

        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 9),
            .foregroundColor: UIColor.black
        ]
        for (i, en) in entetes.enumerated() {
            NSAttributedString(string: en, attributes: headerAttrs).draw(at: CGPoint(x: colX[i] + 4, y: y - 15))
        }
        y -= 24

        // Lignes
        let ligneAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.black
        ]
        let montantRecetteAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.systemGreen
        ]
        let montantDepenseAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.systemRed
        ]

        for (idx, e) in ecrituresFiltrees.enumerated() {
            nouvellePageSiNecessaire(hauteurRequise: 18)

            if idx % 2 == 0 {
                context.setFillColor(UIColor.systemGray6.cgColor)
                context.fill(CGRect(x: margeH, y: y - 14, width: largeurContenu, height: 16))
            }

            let montantAttrs = e.typeEcriture == .recette ? montantRecetteAttrs : montantDepenseAttrs
            let signe = e.typeEcriture == .recette ? "+" : "-"

            let colonnes: [(String, [NSAttributedString.Key: Any])] = [
                (dateFormatter.string(from: e.date), ligneAttrs),
                (String(e.libelle.prefix(35)), ligneAttrs),
                (e.typeEcriture.label, ligneAttrs),
                (e.typeTVANom.isEmpty ? "—" : e.typeTVANom, ligneAttrs),
                ("\(signe)\(e.montantTTC.formatMonetaire)", montantAttrs)
            ]
            for (i, (texte, attrs)) in colonnes.enumerated() {
                NSAttributedString(string: texte, attributes: attrs).draw(at: CGPoint(x: colX[i] + 4, y: y - 11))
            }
            y -= 16
        }

        // Totaux
        y -= 10
        nouvellePageSiNecessaire(hauteurRequise: 60)

        context.setStrokeColor(UIColor.systemGray3.cgColor)
        context.setLineWidth(0.5)
        context.move(to: CGPoint(x: margeH, y: y))
        context.addLine(to: CGPoint(x: margeH + largeurContenu, y: y))
        context.strokePath()
        y -= 10

        let boldAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.black
        ]
        let recetteStr = NSAttributedString(string: "Recettes : +\(totalRecettes.formatMonetaire)", attributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.systemGreen])
        recetteStr.draw(at: CGPoint(x: margeH, y: y - 10))
        y -= 16
        let depenseStr = NSAttributedString(string: "Dépenses : -\(totalDepenses.formatMonetaire)", attributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.systemRed])
        depenseStr.draw(at: CGPoint(x: margeH, y: y - 10))
        y -= 16
        let solde = totalRecettes - totalDepenses
        let soldeStr = NSAttributedString(string: "Solde : \(solde >= 0 ? "+" : "")\(solde.formatMonetaire)", attributes: boldAttrs)
        soldeStr.draw(at: CGPoint(x: margeH, y: y - 10))

        context.endPDFPage()
        context.closePDF()

        return url
    }
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
