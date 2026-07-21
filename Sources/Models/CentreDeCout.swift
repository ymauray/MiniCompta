import SwiftData
import Foundation

@Model
final class CentreDeCout {
    var id: UUID = UUID()
    var nom: String
    var couleurHex: String
    var ordre: Int

    /// Écritures affectées à ce centre (relation multi-centres).
    @Relationship(deleteRule: .nullify, inverse: \Ecriture.centresDeCout)
    var ecritures: [Ecriture] = []

    /// Inverse de l'ancienne relation to-one, conservée le temps de la migration.
    @Relationship(deleteRule: .nullify, inverse: \Ecriture.centreDeCout)
    var ecrituresLegacy: [Ecriture] = []

    init(nom: String, couleurHex: String = "#5E9BF0", ordre: Int = 0) {
        self.id = UUID()
        self.nom = nom
        self.couleurHex = couleurHex
        self.ordre = ordre
    }
}
