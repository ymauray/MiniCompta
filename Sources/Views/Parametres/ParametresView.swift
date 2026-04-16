import SwiftUI
import SwiftData

struct ParametresView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Listes de référence") {
                    NavigationLink("Centres de coût") {
                        ListeConfigurableView<CentreDeCout>(
                            titre: "Centres de coût",
                            ajouterLabel: "Nouveau centre"
                        )
                    }
                    NavigationLink("Catégories") {
                        ListeConfigurableView<Categorie>(
                            titre: "Catégories",
                            ajouterLabel: "Nouvelle catégorie"
                        )
                    }
                    NavigationLink("Types TVA") {
                        ListeTypesTVAView()
                    }
                }

                Section("Export") {
                    NavigationLink("Exporter en PDF") {
                        ExportPDFView()
                    }
                }
            }
            .navigationTitle("Paramètres")
            .listStyle(.insetGrouped)
        }
    }
}

// MARK: - Protocol pour les éléments configurables

protocol ElementConfigurable: PersistentModel {
    var nom: String { get set }
    var couleurHex: String { get set }
    init(nom: String, couleurHex: String)
}

extension CentreDeCout: ElementConfigurable {}
extension Categorie: ElementConfigurable {}

// MARK: - Vue générique pour Centre de coût / Catégorie

struct ListeConfigurableView<T: ElementConfigurable>: View {
    let titre: String
    let ajouterLabel: String

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \T.nom) private var elements: [T]

    @State private var afficherFormulaire = false
    @State private var nomNouveau = ""
    @State private var couleurNouvelle = Color(.systemBlue)
    @State private var elementAModifier: T?

    var body: some View {
        List {
            ForEach(elements) { element in
                HStack {
                    Circle()
                        .fill(Color(hex: element.couleurHex))
                        .frame(width: 14, height: 14)
                    Text(element.nom)
                    Spacer()
                    Button {
                        nomNouveau = element.nom
                        couleurNouvelle = Color(hex: element.couleurHex)
                        elementAModifier = element
                        afficherFormulaire = true
                    } label: {
                        Image(systemName: "pencil")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .onDelete { offsets in
                for i in offsets { modelContext.delete(elements[i]) }
                try? modelContext.save()
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(titre)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    nomNouveau = ""
                    couleurNouvelle = Color(.systemBlue)
                    elementAModifier = nil
                    afficherFormulaire = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $afficherFormulaire) {
            FormulaireElementView(
                titre: elementAModifier == nil ? ajouterLabel : "Modifier",
                nom: $nomNouveau,
                couleur: $couleurNouvelle,
                onValider: {
                    if let e = elementAModifier {
                        e.nom = nomNouveau
                        e.couleurHex = couleurNouvelle.toHex()
                    } else {
                        let nouveau = T(nom: nomNouveau, couleurHex: couleurNouvelle.toHex())
                        modelContext.insert(nouveau)
                    }
                    try? modelContext.save()
                    afficherFormulaire = false
                }
            )
        }
    }
}

// MARK: - Formulaire générique

struct FormulaireElementView: View {
    let titre: String
    @Binding var nom: String
    @Binding var couleur: Color
    let onValider: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("Nom") {
                    TextField("Nom", text: $nom)
                }
                Section("Couleur") {
                    ColorPicker("Couleur d'affichage", selection: $couleur, supportsOpacity: false)
                }
            }
            .navigationTitle(titre)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Valider") { onValider() }
                        .disabled(nom.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Vue Types TVA

struct ListeTypesTVAView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TypeTVA.taux, order: .reverse) private var typesTVA: [TypeTVA]

    @State private var afficherFormulaire = false
    @State private var typeAModifier: TypeTVA?

    var body: some View {
        List {
            ForEach(typesTVA) { t in
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(t.nom).font(.body)
                        Text(t.signification).font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(t.tauxFormate).font(.body.bold())
                        if !t.caseFormulaire.isEmpty {
                            Text("Case \(t.caseFormulaire)").font(.caption2).foregroundStyle(.secondary)
                        }
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    typeAModifier = t
                    afficherFormulaire = true
                }
            }
            .onDelete { offsets in
                for i in offsets { modelContext.delete(typesTVA[i]) }
                try? modelContext.save()
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Types TVA")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    typeAModifier = nil
                    afficherFormulaire = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $afficherFormulaire) {
            FormulaireTVAView(typeTVA: typeAModifier, onValider: {
                afficherFormulaire = false
            })
        }
    }
}

// MARK: - Formulaire TVA

struct FormulaireTVAView: View {
    let typeTVA: TypeTVA?
    let onValider: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var nom: String = ""
    @State private var tauxTexte: String = ""
    @State private var signification: String = ""
    @State private var caseFormulaire: String = ""

    private var valide: Bool {
        !nom.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(tauxTexte.replacingOccurrences(of: ",", with: ".")) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Identification") {
                    TextField("Nom (ex. Normal 8.1%)", text: $nom)
                    TextField("Description", text: $signification)
                }
                Section("Taux") {
                    HStack {
                        TextField("0.0", text: $tauxTexte)
                            .keyboardType(.decimalPad)
                        Text("%")
                            .foregroundStyle(.secondary)
                    }
                }
                Section("Formulaire TVA") {
                    TextField("N° de case (optionnel)", text: $caseFormulaire)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle(typeTVA == nil ? "Nouveau type TVA" : "Modifier")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Annuler") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Valider") { enregistrer() }
                        .disabled(!valide)
                }
            }
            .onAppear {
                if let t = typeTVA {
                    nom = t.nom
                    tauxTexte = String(format: "%.1f", t.taux * 100)
                    signification = t.signification
                    caseFormulaire = t.caseFormulaire
                }
            }
        }
    }

    private func enregistrer() {
        let tauxDecimal = (Double(tauxTexte.replacingOccurrences(of: ",", with: ".")) ?? 0) / 100
        if let t = typeTVA {
            t.nom = nom
            t.taux = tauxDecimal
            t.signification = signification
            t.caseFormulaire = caseFormulaire
        } else {
            let nouveau = TypeTVA(nom: nom, taux: tauxDecimal, signification: signification, caseFormulaire: caseFormulaire)
            modelContext.insert(nouveau)
        }
        try? modelContext.save()
        onValider()
        dismiss()
    }
}
