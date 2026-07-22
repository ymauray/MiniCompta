import SwiftUI
import SwiftData

struct EcritureDetailView: View {
    let ecriture: Ecriture
    @Binding var chemin: [Ecriture]

    @State private var afficherEdition = false
    @State private var afficherDuplication = false

    private var montantHT: Double {
        ecriture.tauxTVA > 0 ? ecriture.montantTTC / (1 + ecriture.tauxTVA) : ecriture.montantTTC
    }

    private var montantTVA: Double { ecriture.montantTTC - montantHT }

    private var couleurMontant: Color {
        ecriture.typeEcriture == .recette ? .green : .red
    }

    var body: some View {
        Form {
            Section("Détails") {
                LabeledContent("Type", value: ecriture.typeEcriture.label)
                LabeledContent("Date") {
                    Text(ecriture.date, format: .dateTime.day().month(.wide).year())
                }
                LabeledContent("Libellé", value: ecriture.libelle.isEmpty ? "—" : ecriture.libelle)
            }

            Section("Montants") {
                LabeledContent("Montant TTC") {
                    Text("\(ecriture.typeEcriture == .recette ? "+" : "-")\(ecriture.montantTTC.formatMonetaire)")
                        .foregroundStyle(couleurMontant)
                }
                if !ecriture.typeTVANom.isEmpty {
                    LabeledContent("Type TVA", value: ecriture.typeTVANom)
                }
                if ecriture.tauxTVA > 0 {
                    LabeledContent("Montant HT") {
                        Text(montantHT.formatMonetaire).foregroundStyle(.secondary)
                    }
                    LabeledContent("Montant TVA") {
                        Text(montantTVA.formatMonetaire).foregroundStyle(.secondary)
                    }
                }
            }

            Section("Classification") {
                LabeledContent("Catégorie") {
                    if let cat = ecriture.categorie {
                        BadgeView(texte: cat.nom, couleurHex: cat.couleurHex)
                    } else {
                        Text("—").foregroundStyle(.secondary)
                    }
                }
                if ecriture.centresDeCout.isEmpty {
                    LabeledContent("Centres de coût", value: "—")
                } else {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Centres de coût")
                            .foregroundStyle(.secondary)
                        FlowLayout(spacing: 6) {
                            ForEach(ecriture.centresDeCout) { centre in
                                BadgeView(texte: centre.nom, couleurHex: centre.couleurHex)
                            }
                        }
                    }
                }
            }

            Section {
                Button {
                    afficherDuplication = true
                } label: {
                    Label("Dupliquer", systemImage: "plus.square.on.square")
                }
            }
        }
        .navigationTitle("Détail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Modifier") { afficherEdition = true }
            }
        }
        .sheet(isPresented: $afficherEdition) {
            EcritureFormView(ecritureExistante: ecriture)
        }
        .sheet(isPresented: $afficherDuplication) {
            EcritureFormView(modele: ecriture) { copie in
                // Remplace le détail courant par celui de la copie (dépile puis
                // empile) : le retour arrière ramène directement au journal, même
                // après une longue chaîne de duplications.
                chemin = Array(chemin.dropLast()) + [copie]
            }
        }
    }
}
