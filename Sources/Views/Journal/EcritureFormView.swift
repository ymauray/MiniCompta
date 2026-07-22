import SwiftUI
import SwiftData
import Observation

struct EcritureFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @Query(sort: \TypeTVA.ordre) private var typesTVA: [TypeTVA]
    @Query(sort: \CentreDeCout.ordre) private var centresDeCout: [CentreDeCout]
    @Query(sort: \Categorie.ordre) private var categories: [Categorie]

    var ecritureExistante: Ecriture?
    /// Écriture source pour une duplication : pré-remplit le formulaire en mode
    /// création (toutes les infos sauf la date, ramenée à aujourd'hui).
    var modele: Ecriture?
    /// Appelé avec la nouvelle écriture après une création réussie (ignoré en édition).
    var onEnregistre: ((Ecriture) -> Void)?

    @State private var typeEcriture: TypeEcriture = .depense
    @State private var date: Date = .now
    @State private var libelle: String = ""
    @State private var montantTTCTexte: String = ""
    @State private var typeTVASelectionne: TypeTVA?
    @State private var centresSelectionnes: [CentreDeCout] = []
    @State private var categorieSelectionnee: Categorie?
    @State private var dejaCharge = false

    private var montantTTC: Double { Double(montantTTCTexte.replacingOccurrences(of: ",", with: ".")) ?? 0 }
    private var tauxTVA: Double { typeTVASelectionne?.taux ?? 0 }
    private var montantHT: Double { tauxTVA > 0 ? montantTTC / (1 + tauxTVA) : montantTTC }
    private var montantTVA: Double { montantTTC - montantHT }

    private var formulaireValide: Bool {
        !libelle.trimmingCharacters(in: .whitespaces).isEmpty && montantTTC > 0
    }

    private var resumeCentres: String {
        switch centresSelectionnes.count {
        case 0: return "Aucun"
        case 1: return centresSelectionnes[0].nom
        default: return "\(centresSelectionnes.count) sélectionnés"
        }
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
                    NavigationLink {
                        SelectionCentresView(
                            centresDisponibles: centresDeCout,
                            centresSelectionnes: $centresSelectionnes
                        )
                    } label: {
                        LabeledContent("Centres de coût") {
                            Text(resumeCentres)
                                .foregroundStyle(centresSelectionnes.isEmpty ? .secondary : .primary)
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
        // Ne charger qu'une fois : `onAppear` se redéclenche au retour de
        // l'écran de sélection des centres et écraserait la saisie en cours.
        guard !dejaCharge else { return }
        dejaCharge = true

        if let e = ecritureExistante {
            typeEcriture = e.typeEcriture
            date = e.date
            libelle = e.libelle
            montantTTCTexte = String(format: "%.2f", e.montantTTC)
            centresSelectionnes = e.centresDeCout
            categorieSelectionnee = e.categorie
            typeTVASelectionne = typesTVA.first { $0.nom == e.typeTVANom }
            return
        }

        if let m = modele {
            // Duplication : on reprend tout, y compris la date d'origine.
            typeEcriture = m.typeEcriture
            date = m.date
            libelle = m.libelle
            montantTTCTexte = String(format: "%.2f", m.montantTTC)
            centresSelectionnes = m.centresDeCout
            categorieSelectionnee = m.categorie
            typeTVASelectionne = typesTVA.first { $0.nom == m.typeTVANom }
            return
        }

        // Création vierge : présélectionne le premier type de TVA.
        if let premier = typesTVA.first {
            typeTVASelectionne = premier
        }
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
            e.centresDeCout = centresSelectionnes
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
                centresDeCout: centresSelectionnes,
                categorie: categorieSelectionnee
            )
            modelContext.insert(nouvelle)
            try? modelContext.save()
            onEnregistre?(nouvelle)
        }
        dismiss()
    }
}

// MARK: - Sélection multiple des centres de coût

struct SelectionCentresView: View {
    let centresDisponibles: [CentreDeCout]
    @Binding var centresSelectionnes: [CentreDeCout]

    var body: some View {
        List {
            if centresDisponibles.isEmpty {
                Text("Aucun centre de coût — ajoutez-en dans Paramètres")
                    .foregroundStyle(.secondary)
                    .font(.footnote)
            } else {
                ForEach(centresDisponibles) { centre in
                    Button {
                        basculer(centre)
                    } label: {
                        HStack {
                            Circle()
                                .fill(Color(hex: centre.couleurHex))
                                .frame(width: 10, height: 10)
                            Text(centre.nom)
                                .foregroundStyle(.primary)
                            Spacer()
                            if estSelectionne(centre) {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.tint)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("Centres de coût")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func estSelectionne(_ centre: CentreDeCout) -> Bool {
        centresSelectionnes.contains { $0.id == centre.id }
    }

    private func basculer(_ centre: CentreDeCout) {
        if let index = centresSelectionnes.firstIndex(where: { $0.id == centre.id }) {
            centresSelectionnes.remove(at: index)
        } else {
            centresSelectionnes.append(centre)
        }
    }
}
