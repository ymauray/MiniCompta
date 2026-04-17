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
        let centreDeCoutId: UUID?
    }
}
