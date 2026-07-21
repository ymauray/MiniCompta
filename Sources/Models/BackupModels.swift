import Foundation

/// Structure regroupant l'intégralité des données pour l'export/import
struct DonneesSauvegarde: Codable {
    let version: Int
    let dateExport: Date
    let codeDevise: String?
    let categories: [CategorieDTO]
    let centresDeCout: [CentreDeCoutDTO]
    let typesTVA: [TypeTVADTO]
    let ecritures: [EcritureDTO]
    
    struct CategorieDTO: Codable {
        let id: UUID
        let nom: String
        let couleurHex: String
        let ordre: Int
    }
    
    struct CentreDeCoutDTO: Codable {
        let id: UUID
        let nom: String
        let couleurHex: String
        let ordre: Int
    }
    
    struct TypeTVADTO: Codable {
        let nom: String
        let taux: Double
        let signification: String
        let ordre: Int
    }
    
    struct EcritureDTO: Codable {
        let date: Date
        let libelle: String
        let typeEcriture: String // "recette" ou "depense"
        let montantTTC: Double
        let tauxTVA: Double
        let typeTVANom: String
        let categorieId: UUID?
        /// Ancien format (v1) : un seul centre de coût. Lu à l'import pour compat.
        let centreDeCoutId: UUID?
        /// Nouveau format (v2) : plusieurs centres de coût.
        let centreDeCoutIds: [UUID]?

        /// Identifiants des centres, quel que soit le format de la sauvegarde.
        var centresIds: [UUID] {
            if let ids = centreDeCoutIds { return ids }
            if let id = centreDeCoutId { return [id] }
            return []
        }
    }
}
