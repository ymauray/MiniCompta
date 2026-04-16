import SwiftData
import Foundation

@Model
final class Categorie {
    var nom: String
    var couleurHex: String
    var ordre: Int

    @Relationship(deleteRule: .nullify, inverse: \Ecriture.categorie)
    var ecritures: [Ecriture] = []

    init(nom: String, couleurHex: String = "#F0825E", ordre: Int = 0) {
        self.nom = nom
        self.couleurHex = couleurHex
        self.ordre = ordre
    }
}
