import SwiftData
import Foundation

@Model
final class CentreDeCout {
    var nom: String
    var couleurHex: String
    var ordre: Int

    @Relationship(deleteRule: .nullify, inverse: \Ecriture.centreDeCout)
    var ecritures: [Ecriture] = []

    init(nom: String, couleurHex: String = "#5E9BF0", ordre: Int = 0) {
        self.nom = nom
        self.couleurHex = couleurHex
        self.ordre = ordre
    }
}
