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
        let descripteur = FetchDescriptor<TypeTVA>()
        let count = (try? modelContext.fetchCount(descripteur)) ?? 0
        guard count == 0 else { return }
        for tva in TypeTVA.seedData {
            modelContext.insert(tva)
        }
        try? modelContext.save()
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

    func exporterDonnees() -> URL? {
        do {
            let fetchCategories = FetchDescriptor<Categorie>()
            let categories = try modelContext.fetch(fetchCategories)
            
            let fetchCentres = FetchDescriptor<CentreDeCout>()
            let centres = try modelContext.fetch(fetchCentres)
            
            let fetchTVA = FetchDescriptor<TypeTVA>()
            let tvas = try modelContext.fetch(fetchTVA)
            
            let fetchEcritures = FetchDescriptor<Ecriture>()
            let ecritures = try modelContext.fetch(fetchEcritures)
            
            let backup = DonneesSauvegarde(
                version: 1,
                dateExport: .now,
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

    func importerDonnees(depuis url: URL) throws {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let backup = try decoder.decode(DonneesSauvegarde.self, from: data)
        
        // 1. Tout effacer (ordre important pour les relations)
        try modelContext.delete(model: Ecriture.self)
        try modelContext.delete(model: Categorie.self)
        try modelContext.delete(model: CentreDeCout.self)
        try modelContext.delete(model: TypeTVA.self)
        
        // 2. Réinsérer les listes de référence et créer des dictionnaires pour reconnecter
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
        
        // 3. Réinsérer les écritures
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

    func reinitialiserToutesLesDonnees() throws {
        // 1. Déconnecter les relations pour éviter les erreurs de "nullify" pendant la suppression massive
        let descripteur = FetchDescriptor<Ecriture>()
        let ecritures = try modelContext.fetch(descripteur)
        for e in ecritures {
            e.categorie = nil
            e.centreDeCout = nil
        }
        try modelContext.save()

        // 2. Suppression massive
        try modelContext.delete(model: Ecriture.self)
        try modelContext.delete(model: Categorie.self)
        try modelContext.delete(model: CentreDeCout.self)
        try modelContext.delete(model: TypeTVA.self)
        
        try modelContext.save()
        
        // 3. Réinjection des données de base
        for tva in TypeTVA.seedData {
            modelContext.insert(tva)
        }
        try modelContext.save()
    }
}
