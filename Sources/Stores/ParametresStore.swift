import SwiftData
import Foundation
import Observation

@Observable
final class ParametresStore {
    private let modelContext: ModelContext

    init(modelContext: ModelContext) {
        self.modelContext = modelContext
        seedSiNecessaire()
    }

    // MARK: - Seed initial

    private func seedSiNecessaire() {
        // 1. Seed des types TVA (toujours nécessaire si vide)
        let descripteur = FetchDescriptor<TypeTVA>()
        let count = (try? modelContext.fetchCount(descripteur)) ?? 0
        if count == 0 {
            for tva in TypeTVA.seedData {
                modelContext.insert(tva)
            }
        }

        // 2. Injection des données de démo (une seule fois au premier lancement ET si vide)
        let dejaInjecte = UserDefaults.standard.bool(forKey: "app.demo_donnees_injectees")
        let fetchEcritures = FetchDescriptor<Ecriture>()
        let nbEcritures = (try? modelContext.fetchCount(fetchEcritures)) ?? 0

        if !dejaInjecte && nbEcritures == 0 {
            injecterDonneesDemo()
            UserDefaults.standard.set(true, forKey: "app.demo_donnees_injectees")
            // Signal pour l'affichage du message dans la vue
            UserDefaults.standard.set(true, forKey: "app.doit_afficher_message_demo")
        }

        try? modelContext.save()
    }

    private func injecterDonneesDemo() {
        // Catégories
        let catLogiciel = Categorie(nom: "Logiciel", couleurHex: "#5E9BF0")
        let catMateriel = Categorie(nom: "Matériel", couleurHex: "#F0825E")
        let catServices = Categorie(nom: "Services", couleurHex: "#7BC67E")
        [catLogiciel, catMateriel, catServices].forEach { modelContext.insert($0) }

        // Centres de coût
        let centreStructure = CentreDeCout(nom: "Structure", couleurHex: "#9B59B6")
        let centreProduit = CentreDeCout(nom: "Produit 1", couleurHex: "#E74C3C")
        [centreStructure, centreProduit].forEach { modelContext.insert($0) }

        // Récupération des types TVA injectés juste avant
        let tvas = TypeTVA.seedData // On utilise les mêmes noms/taux pour la démo

        // Génération d'écritures sur les 7 derniers jours
        let libelles = ["Achat licence IDE", "Serveur Cloud mensuel", "Nouvel écran 4K", "Consulting Architecture", "Fournitures bureau", "Vente licence Pro", "Maintenance site web"]
        let montants = [150.0, 45.0, 450.0, 1200.0, 35.0, 500.0, 200.0]
        
        for i in 0..<7 {
            let date = Calendar.current.date(byAdding: .day, value: -i, to: .now) ?? .now
            let type: TypeEcriture = (i == 5) ? .recette : .depense // La 6ème est une recette
            
            // On alterne les combinaisons
            let tva = tvas[i % tvas.count]
            let cat = i % 2 == 0 ? catLogiciel : (i % 3 == 0 ? catMateriel : catServices)
            let centre = i % 2 == 0 ? centreStructure : centreProduit

            let e = Ecriture(
                date: date,
                libelle: libelles[i],
                typeEcriture: type,
                montantTTC: montants[i],
                tauxTVA: tva.taux,
                typeTVANom: tva.nom,
                centreDeCout: centre,
                categorie: cat
            )
            modelContext.insert(e)
        }
    }

    // MARK: - Types TVA

    func typesTVA() -> [TypeTVA] {
        let descripteur = FetchDescriptor<TypeTVA>(sortBy: [SortDescriptor(\.ordre)])
        return (try? modelContext.fetch(descripteur)) ?? []
    }

    func ajouterTypeTVA(nom: String, taux: Double, signification: String) {
        let t = TypeTVA(nom: nom, taux: taux, signification: signification)
        modelContext.insert(t)
        try? modelContext.save()
    }

    func supprimerTypeTVA(_ typeTVA: TypeTVA) {
        modelContext.delete(typeTVA)
        try? modelContext.save()
    }

    // MARK: - Centres de coût

    func centresDeCout() -> [CentreDeCout] {
        let descripteur = FetchDescriptor<CentreDeCout>(sortBy: [SortDescriptor(\.nom)])
        return (try? modelContext.fetch(descripteur)) ?? []
    }

    func ajouterCentreDeCout(nom: String, couleurHex: String) {
        let c = CentreDeCout(nom: nom, couleurHex: couleurHex)
        modelContext.insert(c)
        try? modelContext.save()
    }

    func supprimerCentreDeCout(_ centre: CentreDeCout) {
        modelContext.delete(centre)
        try? modelContext.save()
    }

    // MARK: - Catégories

    func categories() -> [Categorie] {
        let descripteur = FetchDescriptor<Categorie>(sortBy: [SortDescriptor(\.nom)])
        return (try? modelContext.fetch(descripteur)) ?? []
    }

    func ajouterCategorie(nom: String, couleurHex: String) {
        let c = Categorie(nom: nom, couleurHex: couleurHex)
        modelContext.insert(c)
        try? modelContext.save()
    }

    func supprimerCategorie(_ categorie: Categorie) {
        modelContext.delete(categorie)
        try? modelContext.save()
    }

    // MARK: - Sauvegarde & Import

    @MainActor
    func exporterDonnees() -> URL? {
        do {
            let fetchCategories = FetchDescriptor<Categorie>(sortBy: [SortDescriptor(\.ordre)])
            let categories = try modelContext.fetch(fetchCategories)
            
            let fetchCentres = FetchDescriptor<CentreDeCout>(sortBy: [SortDescriptor(\.ordre)])
            let centres = try modelContext.fetch(fetchCentres)
            
            let fetchTVA = FetchDescriptor<TypeTVA>(sortBy: [SortDescriptor(\.ordre)])
            let tvas = try modelContext.fetch(fetchTVA)
            
            let fetchEcritures = FetchDescriptor<Ecriture>()
            let ecritures = try modelContext.fetch(fetchEcritures)
            
            let backup = DonneesSauvegarde(
                version: 1,
                dateExport: .now,
                codeDevise: DeviseStore.shared.codeDevise,
                categories: categories.map { .init(id: $0.id, nom: $0.nom, couleurHex: $0.couleurHex, ordre: $0.ordre) },
                centresDeCout: centres.map { .init(id: $0.id, nom: $0.nom, couleurHex: $0.couleurHex, ordre: $0.ordre) },
                typesTVA: tvas.map { .init(nom: $0.nom, taux: $0.taux, signification: $0.signification, ordre: $0.ordre) },
                ecritures: ecritures.map { .init(
                    date: $0.date,
                    libelle: $0.libelle,
                    typeEcriture: $0.typeEcriture.rawValue,
                    montantTTC: $0.montantTTC,
                    tauxTVA: $0.tauxTVA,
                    typeTVANom: $0.typeTVANom,
                    categorieId: $0.categorie?.id,
                    centreDeCoutId: $0.centreDeCout?.id
                )}
            )
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            let data = try encoder.encode(backup)
            
            let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("MiniCompta_Backup.json")
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Erreur d'export : \(error)")
            return nil
        }
    }

    @MainActor
    func importerDonnees(depuis url: URL) async throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(DonneesSauvegarde.self, from: data)
        
        // 1. Tout effacer proprement
        try effacerTout()
        
        // 2. Restaurer la devise
        if let code = backup.codeDevise {
            DeviseStore.shared.codeDevise = code
        }
        
        // 3. Réinsérer les listes de référence et créer des dictionnaires pour reconnecter
        var catMap: [UUID: Categorie] = [:]
        for cDTO in backup.categories {
            let c = Categorie(nom: cDTO.nom, couleurHex: cDTO.couleurHex, ordre: cDTO.ordre)
            c.id = cDTO.id
            modelContext.insert(c)
            catMap[c.id] = c
        }
        
        var centreMap: [UUID: CentreDeCout] = [:]
        for cDTO in backup.centresDeCout {
            let c = CentreDeCout(nom: cDTO.nom, couleurHex: cDTO.couleurHex, ordre: cDTO.ordre)
            c.id = cDTO.id
            modelContext.insert(c)
            centreMap[c.id] = c
        }
        
        for tDTO in backup.typesTVA {
            let t = TypeTVA(nom: tDTO.nom, taux: tDTO.taux, signification: tDTO.signification, ordre: tDTO.ordre)
            modelContext.insert(t)
        }
        
        // 4. Réinsérer les écritures
        for eDTO in backup.ecritures {
            let e = Ecriture(
                date: eDTO.date,
                libelle: eDTO.libelle,
                typeEcriture: TypeEcriture(rawValue: eDTO.typeEcriture) ?? .depense,
                montantTTC: eDTO.montantTTC,
                tauxTVA: eDTO.tauxTVA,
                typeTVANom: eDTO.typeTVANom,
                centreDeCout: eDTO.centreDeCoutId != nil ? centreMap[eDTO.centreDeCoutId!] : nil,
                categorie: eDTO.categorieId != nil ? catMap[eDTO.categorieId!] : nil
            )
            modelContext.insert(e)
        }
        
        try modelContext.save()
    }

    @MainActor
    func reinitialiserToutesLesDonnees() async throws {
        // 1. Tout effacer proprement
        try effacerTout()
        
        // 2. Réinjection des données de base
        for tva in TypeTVA.seedData {
            modelContext.insert(tva)
        }
        
        // 3. Réinitialisation de la devise
        DeviseStore.shared.codeDevise = "EUR"
        
        try modelContext.save()
    }

    /// Supprime proprement toutes les données en gérant les relations SwiftData
    @MainActor
    private func effacerTout() throws {
        // 1. Déconnecter les relations pour éviter les erreurs de "nullify" pendant la suppression massive
        let descripteur = FetchDescriptor<Ecriture>()
        let ecritures = try modelContext.fetch(descripteur)
        for e in ecritures {
            e.categorie = nil
            e.centreDeCout = nil
        }
        // On sauvegarde pour persister la rupture des liens avant le batch delete
        try modelContext.save()

        // 2. Suppression massive (Batch Delete)
        // L'ordre importe peu une fois les relations nullifiées
        try modelContext.delete(model: Ecriture.self)
        try modelContext.delete(model: Categorie.self)
        try modelContext.delete(model: CentreDeCout.self)
        try modelContext.delete(model: TypeTVA.self)
        
        try modelContext.save()
    }
}
