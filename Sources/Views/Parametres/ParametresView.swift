import SwiftUI
import SwiftData
import Observation

struct ParametresView: View {
    var body: some View {
        @Bindable var deviseStore = DeviseStore.shared
        
        NavigationStack {
            List {
                Section("Préférences") {
                    Picker("Devise", selection: $deviseStore.codeDevise) {
                        ForEach(DeviseStore.devisesDisponibles, id: \.0) { code, label in
                            Text(label).tag(code)
                        }
                    }
                    .pickerStyle(.menu)
                }

                Section("Listes de référence") {
                    NavigationLink("Centres de coût") {
                        ListeConfigurableView<CentreDeCout>(
                            titre: "Centres de coût",
                            ajouterLabel: "Nouveau centre",
                            creerElement: { nom, couleur, ordre in CentreDeCout(nom: nom, couleurHex: couleur, ordre: ordre) }
                        )
                    }
                    NavigationLink("Catégories") {
                        ListeConfigurableView<Categorie>(
                            titre: "Catégories",
                            ajouterLabel: "Nouvelle catégorie",
                            creerElement: { nom, couleur, ordre in Categorie(nom: nom, couleurHex: couleur, ordre: ordre) }
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
    var ordre: Int { get set }
}

extension CentreDeCout: ElementConfigurable {}
extension Categorie: ElementConfigurable {}

// MARK: - Vue générique pour Centre de coût / Catégorie

struct ListeConfigurableView<T: ElementConfigurable>: View {
    let titre: String
    let ajouterLabel: String
    let creerElement: (String, String, Int) -> T

    @Environment(\.modelContext) private var modelContext
    @Query(sort: \T.ordre) private var elements: [T]

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
                .swipeActions(edge: .leading) {
                    Button {
                        let copie = creerElement(element.nom, element.couleurHex, elements.count)
                        modelContext.insert(copie)
                        try? modelContext.save()
                    } label: {
                        Label("Dupliquer", systemImage: "doc.on.doc")
                    }
                    .tint(.blue)
                }
            }
            .onDelete { offsets in
                for i in offsets { modelContext.delete(elements[i]) }
                try? modelContext.save()
            }
            .onMove { source, destination in
                var liste = elements
                liste.move(fromOffsets: source, toOffset: destination)
                for (index, element) in liste.enumerated() {
                    element.ordre = index
                }
                try? modelContext.save()
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(titre)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    EditButton()
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
                        let nouveau = creerElement(nomNouveau, couleurNouvelle.toHex(), elements.count)
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
                        .clearable($nom)
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
    @Query(sort: \TypeTVA.ordre) private var typesTVA: [TypeTVA]

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
                    }
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    typeAModifier = t
                    afficherFormulaire = true
                }
                .swipeActions(edge: .leading) {
                    Button {
                        let copie = TypeTVA(nom: t.nom, taux: t.taux, signification: t.signification, ordre: typesTVA.count)
                        modelContext.insert(copie)
                        try? modelContext.save()
                    } label: {
                        Label("Dupliquer", systemImage: "doc.on.doc")
                    }
                    .tint(.blue)
                }
            }
            .onDelete { offsets in
                for i in offsets { modelContext.delete(typesTVA[i]) }
                try? modelContext.save()
            }
            .onMove { source, destination in
                var liste = typesTVA
                liste.move(fromOffsets: source, toOffset: destination)
                for (index, tva) in liste.enumerated() {
                    tva.ordre = index
                }
                try? modelContext.save()
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Types TVA")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack {
                    EditButton()
                    Button {
                        typeAModifier = nil
                        afficherFormulaire = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $afficherFormulaire) {
            FormulaireTVAView(typeTVA: typeAModifier, ordreProchain: typesTVA.count, onValider: {
                afficherFormulaire = false
            })
        }
    }
}

// MARK: - Formulaire TVA

struct FormulaireTVAView: View {
    let typeTVA: TypeTVA?
    let ordreProchain: Int
    let onValider: () -> Void

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var nom: String = ""
    @State private var tauxTexte: String = ""
    @State private var signification: String = ""

    private var valide: Bool {
        !nom.trimmingCharacters(in: .whitespaces).isEmpty &&
        Double(tauxTexte.replacingOccurrences(of: ",", with: ".")) != nil
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Identification") {
                    TextField("Nom (ex. Normal 20%)", text: $nom)
                        .clearable($nom)
                    TextField("Description", text: $signification)
                        .clearable($signification)
                }
                Section("Taux") {
                    HStack {
                        TextField("0.0", text: $tauxTexte)
                            .keyboardType(.decimalPad)
                            .clearable($tauxTexte)
                        Text("%")
                            .foregroundStyle(.secondary)
                    }
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
        } else {
            let nouveau = TypeTVA(nom: nom, taux: tauxDecimal, signification: signification, ordre: ordreProchain)
            modelContext.insert(nouveau)
        }
        try? modelContext.save()
        onValider()
        dismiss()
    }
}

// MARK: - Modificateur champ effaçable

private struct ClearableModifier: ViewModifier {
    @Binding var text: String

    func body(content: Content) -> some View {
        HStack {
            content
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

extension View {
    func clearable(_ text: Binding<String>) -> some View {
        modifier(ClearableModifier(text: text))
    }
}
