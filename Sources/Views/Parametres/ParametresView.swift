import SwiftUI
import SwiftData
import Observation
import UniformTypeIdentifiers
struct ParametresView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var afficherAlerteExport = false
    @State private var afficherAlerteImport = false
    @State private var urlExport: URL?
    @State private var afficherShareSheet = false
    @State private var afficherFileImporter = false
    @State private var afficherAlerteReinitialisation = false
    @State private var afficherConfirmationImport = false
    @State private var afficherConfirmationReinitialisation = false

    // On garde une seule instance du store pour la durée de vie de la vue
    @State private var store: ParametresStore?
    var body: some View {
        let currentStore = store ?? ParametresStore(modelContext: modelContext)

        NavigationStack {
            List {
                Section("Préférences") {
                    Picker("Devise", selection: Bindable(DeviseStore.shared).codeDevise) {
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

                Section(header: Text("Sauvegarde & Import"), footer: Text("L'importation remplacera toutes vos données actuelles par celles du fichier sélectionné.")) {
                    Button {
                        afficherAlerteExport = true
                    } label: {
                        Label("Exporter toutes les données (JSON)", systemImage: "square.and.arrow.up")
                    }
                    
                    Button(role: .destructive) {
                        afficherAlerteImport = true
                    } label: {
                        Label("Importer des données (JSON)", systemImage: "square.and.arrow.down")
                    }
                }

                Section {
                    Button(role: .destructive) {
                        afficherAlerteReinitialisation = true
                    } label: {
                        Label("Réinitialiser l'application", systemImage: "trash")
                    }
                }
            }
            .navigationTitle("Paramètres")
            .listStyle(.insetGrouped)
            .alert("Sécurité des données", isPresented: $afficherAlerteExport) {
                Button("Continuer") {
                    if let url = currentStore.exporterDonnees() {
                        urlExport = url
                        afficherShareSheet = true
                    }
                }
                Button("Annuler", role: .cancel) { }
            } message: {
                Text("Une fois exportées, vos données comptables ne sont plus protégées par le bac à sable de l'application. Vous êtes seul responsable de leur sécurité et de leur confidentialité.")
            }
            .alert("Confirmer l'importation", isPresented: $afficherAlerteImport) {
                Button("Sélectionner le fichier", role: .destructive) {
                    afficherFileImporter = true
                }
                Button("Annuler", role: .cancel) { }
            } message: {
                Text("Cette opération va supprimer DÉFINITIVEMENT toutes les écritures et listes de référence actuelles pour les remplacer par celles du fichier importé. Cette action est irréversible.")
            }
            .sheet(isPresented: $afficherShareSheet) {
                if let url = urlExport {
                    ShareSheet(activityItems: [url])
                }
            }
            .alert("Réinitialiser l'application ?", isPresented: $afficherAlerteReinitialisation) {
                Button("Tout effacer", role: .destructive) {
                    Task {
                        do {
                            try await currentStore.reinitialiserToutesLesDonnees()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                afficherConfirmationReinitialisation = true
                            }
                        } catch {
                            print("Erreur lors de la réinitialisation : \(error)")
                        }
                    }
                }
                Button("Annuler", role: .cancel) { }
            } message: {
                Text("Cette action va supprimer TOUTES vos écritures, catégories, centres de coût et types de TVA. Vous retrouverez l'application dans son état d'origine.")
            }
            .alert("Importation réussie", isPresented: $afficherConfirmationImport) {
                Button("OK") { }
            } message: {
                Text("Vos données ont été restaurées avec succès.")
            }
            .alert("Réinitialisation terminée", isPresented: $afficherConfirmationReinitialisation) {
                Button("OK") { }
            } message: {
                Text("L'application a été remise dans son état d'origine.")
            }
            .fileImporter(
                isPresented: $afficherFileImporter,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        Task {
                            do {
                                // Nécessaire pour accéder aux fichiers hors bac à sable
                                if url.startAccessingSecurityScopedResource() {
                                    defer { url.stopAccessingSecurityScopedResource() }
                                    try await currentStore.importerDonnees(depuis: url)
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        afficherConfirmationImport = true
                                    }
                                }
                            } catch {
                                print("Erreur d'import : \(error)")
                            }
                        }
                    }
                case .failure(let error):
                    print("Erreur sélection fichier : \(error)")
                }
            }
            .onAppear {
                if store == nil {
                    store = ParametresStore(modelContext: modelContext)
                }
            }
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
                }
                .contentShape(Rectangle())
                .onTapGesture {
                    nomNouveau = element.nom
                    couleurNouvelle = Color(hex: element.couleurHex)
                    elementAModifier = element
                    afficherFormulaire = true
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
