import SwiftData
import Foundation

@Model
final class Categorie {
    var nom: String
    var couleurHex: String

    @Relationship(deleteRule: .nullify, inverse: \Ecriture.categorie)
    var ecritures: [Ecriture] = []

    init(nom: String, couleurHex: String = "#F0825E") {
        self.nom = nom
        self.couleurHex = couleurHex
    }
}
