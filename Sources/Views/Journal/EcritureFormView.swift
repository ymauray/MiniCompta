import SwiftUI
import SwiftData
import Observation

struct EcritureFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \TypeTVA.ordre) private var typesTVA: [TypeTVA]
    @Query(sort: \CentreDeCout.nom) private var centresDeCout: [CentreDeCout]
    @Query(sort: \Categorie.nom) private var categories: [Categorie]

    var ecritureExistante: Ecriture?

    @State private var typeEcriture: TypeEcriture = .depense
    @State private var date: Date = .now
    @State private var libelle: String = ""
    @State private var montantTTCTexte: String = ""
    @State private var typeTVASelectionne: TypeTVA?
    @State private var centreSelectionne: CentreDeCout?
    @State private var categorieSelectionnee: Categorie?

    private var montantTTC: Double { Double(montantTTCTexte.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var tauxTVA: Double { typeTVASelectionne?.taux ?? 0 }
    private var montantHT: Double { tauxTVA > 0 ? montantTTC / (1 + tauxTVA) : montantTTC }
    private var montantTVA: Double { montantTTC - montantHT }

    private var formulaireValide: Bool {
        !libelle.trimmingCharacters(in: .whitespaces).isEmpty && montantTTC > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                // Type
                Section {
                    Picker("", selection: $typeEcriture) {
                        ForEach(TypeEcriture.allCases, id: \.self) { t in
                            Text(t.label).tag(t)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                // Informations principales
                Section("Détails") {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                    TextField("Libellé", text: $libelle)
                    HStack {
                        Text("Montant TTC")
                        Spacer()
                        TextField("0.00", text: $montantTTCTexte)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(DeviseStore.shared.symboleDevise)
                            .foregroundStyle(.secondary)
                    }
                }

                // TVA
                Section("TVA") {
                    if typesTVA.isEmpty {
                        Text("Aucun type TVA — ajoutez-en dans Paramètres")
                            .foregroundStyle(.secondary)
                            .font(.footnote)
                    } else {
                        Picker("Type TVA", selection: $typeTVASelectionne) {
                            Text("Aucun").tag(Optional<TypeTVA>.none)
                            ForEach(typesTVA) { t in
                                Text("\(t.nom) (\(t.tauxFormate))").tag(Optional(t))
                            }
                        }
                    }
                    if montantTTC > 0 && tauxTVA > 0 {
                        LabeledContent("Montant HT") {
                            Text(montantHT.formatMonetaire)
                                .foregroundStyle(.secondary)
                        }
                        LabeledContent("Montant TVA") {
                            Text(montantTVA.formatMonetaire)
                                .foregroundStyle(.secondary)
                        }
                    }
                }

                // Classification
                Section("Classification") {
                    Picker("Catégorie", selection: $categorieSelectionnee) {
                        Text("Aucune").tag(Optional<Categorie>.none)
                        ForEach(categories) { c in
                            HStack {
                                Circle()
                                    .fill(Color(hex: c.couleurHex))
                                    .frame(width: 10, height: 10)
                                Text(c.nom)
                            }.tag(Optional(c))
                        }
                    }
                    Picker("Centre de coût", selection: $centreSelectionne) {
                        Text("Aucun").tag(Optional<CentreDeCout>.none)
                        ForEach(centresDeCout) { c in
                            HStack {
                                Circle()
                                    .fill(Color(hex: c.couleurHex))
                                    .frame(width: 10, height: 10)
                                Text(c.nom)
                            }.tag(Optional(c))
                        }
                    }
                }
            }
            .navigationTitle(ecritureExistante == nil ? "Nouvelle écriture" : "Modifier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Enregistrer") { enregistrer() }
                        .disabled(!formulaireValide)
                }
            }
            .onAppear { chargerEcritureExistante() }
        }
    }

    // MARK: - Actions

    private func chargerEcritureExistante() {
        guard let e = ecritureExistante else {
            if let premier = typesTVA.first {
                typeTVASelectionne = premier
            }
            return
        }
        typeEcriture = e.typeEcriture
        date = e.date
        libelle = e.libelle
        montantTTCTexte = String(format: "%.2f", e.montantTTC)
        centreSelectionne = e.centreDeCout
        categorieSelectionnee = e.categorie
        typeTVASelectionne = typesTVA.first { $0.nom == e.typeTVANom }
    }

    private func enregistrer() {
        let taux = typeTVASelectionne?.taux ?? 0
        let nomTVA = typeTVASelectionne?.nom ?? ""

        if let e = ecritureExistante {
            e.typeEcriture = typeEcriture
            e.date = date
            e.libelle = libelle
            e.montantTTC = montantTTC
            e.tauxTVA = taux
            e.typeTVANom = nomTVA
            e.centreDeCout = centreSelectionne
            e.categorie = categorieSelectionnee
            try? modelContext.save()
        } else {
            let nouvelle = Ecriture(
                date: date,
                libelle: libelle,
                typeEcriture: typeEcriture,
                montantTTC: montantTTC,
                tauxTVA: taux,
                typeTVANom: nomTVA,
                centreDeCout: centreSelectionne,
                categorie: categorieSelectionnee
            )
            modelContext.insert(nouvelle)
            try? modelContext.save()
        }
        dismiss()
    }
}
