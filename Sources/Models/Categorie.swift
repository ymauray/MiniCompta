import SwiftData
import Foundation

@Model
final class Categorie {
    var id: UUID = UUID()
    var nom: String
    var couleurHex: String
    var ordre: Int

    @Relationship(deleteRule: .nullify, inverse: \Ecriture.categorie)
    var ecritures: [Ecriture] = []

    init(nom: String, couleurHex: String = "#F0825E", ordre: Int = 0) {
        self.id = UUID()
        self.nom = nom
        self.couleurHex = couleurHex
        self.ordre = ordre
    }
}
