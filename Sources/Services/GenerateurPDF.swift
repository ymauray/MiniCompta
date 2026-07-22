import UIKit

/// Génère un PDF (journal comptable, A4 paysage) à partir d'un ensemble
/// d'écritures déjà filtrées. Réutilisable depuis n'importe quel écran.
enum GenerateurPDF {

    /// - Parameters:
    ///   - ecritures: écritures à inclure (triées par date croissante en interne).
    ///   - sousTitre: description de la période affichée sous le titre (ex. « Du … au … »).
    ///   - centres: tous les centres de coût, pour le récapitulatif.
    ///   - typesTVA: tous les types de TVA, pour le récapitulatif.
    @MainActor
    static func generer(
        ecritures: [Ecriture],
        sousTitre: String,
        centres: [CentreDeCout],
        typesTVA: [TypeTVA]
    ) -> URL? {
        let lignes = ecritures.sorted { $0.date < $1.date }
        let totalRecettes = lignes.filter { $0.typeEcriture == .recette }.reduce(0) { $0 + $1.montantTTC }
        let totalDepenses = lignes.filter { $0.typeEcriture == .depense }.reduce(0) { $0 + $1.montantTTC }

        let dateFormatter = DateFormatter()
        dateFormatter.locale = .autoupdatingCurrent
        dateFormatter.dateStyle = .short

        let pageRect = CGRect(x: 0, y: 0, width: 841.8, height: 595.2) // A4 Paysage
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("journal_\(Int(Date().timeIntervalSince1970)).pdf")

        UIGraphicsBeginPDFContextToFile(url.path(), pageRect, nil)

        let margeH: CGFloat = 40
        let margeV: CGFloat = 40
        let largeurContenu = pageRect.width - 2 * margeH
        var y: CGFloat = margeV

        func dessinerEntete() {
            let titreAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.boldSystemFont(ofSize: 18),
                .foregroundColor: UIColor.black
            ]
            let titre = NSAttributedString(string: "Journal comptable", attributes: titreAttrs)
            titre.draw(at: CGPoint(x: margeH, y: y))

            let sousAttrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 11),
                .foregroundColor: UIColor.gray
            ]
            let sous = NSAttributedString(string: sousTitre, attributes: sousAttrs)
            sous.draw(at: CGPoint(x: margeH, y: y + 22))

            y += 60
        }

        func nouvellePageSiNecessaire(hauteurRequise: CGFloat) {
            if y + hauteurRequise > pageRect.height - margeV {
                UIGraphicsBeginPDFPage()
                y = margeV
                dessinerEntete()
            }
        }

        UIGraphicsBeginPDFPage()
        dessinerEntete()

        // En-tête tableau (Format Paysage)
        // Colonnes : Date (80), Libellé (220), Centre (100), Type TVA (100), Taux (60), TVA (100), TTC (100)
        let colW: [CGFloat] = [80, 220, 100, 100, 60, 100, 100]
        let colX: [CGFloat] = [
            margeH,
            margeH + colW[0],
            margeH + colW[0] + colW[1],
            margeH + colW[0] + colW[1] + colW[2],
            margeH + colW[0] + colW[1] + colW[2] + colW[3],
            margeH + colW[0] + colW[1] + colW[2] + colW[3] + colW[4],
            margeH + colW[0] + colW[1] + colW[2] + colW[3] + colW[4] + colW[5]
        ]
        let entetes = ["Date", "Libellé", "Centre", "Type TVA", "Taux", "Montant TVA", "Montant TTC"]

        nouvellePageSiNecessaire(hauteurRequise: 30)
        if let context = UIGraphicsGetCurrentContext() {
            context.setFillColor(UIColor.systemBlue.withAlphaComponent(0.15).cgColor)
            context.fill(CGRect(x: margeH, y: y, width: largeurContenu, height: 20))
        }

        let headerAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 9),
            .foregroundColor: UIColor.black
        ]
        for (i, en) in entetes.enumerated() {
            let alignment: NSTextAlignment = i >= 4 ? .right : .left
            let paragraphStyle = NSMutableParagraphStyle()
            paragraphStyle.alignment = alignment

            var attrs = headerAttrs
            attrs[.paragraphStyle] = paragraphStyle

            let rect = CGRect(x: colX[i] + (i >= 4 ? -4 : 4), y: y + 5, width: colW[i], height: 15)
            NSAttributedString(string: en, attributes: attrs).draw(in: rect)
        }
        y += 24

        // Lignes
        let ligneAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.black
        ]
        let montantRecetteAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.systemGreen
        ]
        let montantDepenseAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 9),
            .foregroundColor: UIColor.systemRed
        ]

        for (idx, e) in lignes.enumerated() {
            nouvellePageSiNecessaire(hauteurRequise: 20)

            if idx % 2 == 0 {
                if let context = UIGraphicsGetCurrentContext() {
                    context.setFillColor(UIColor.systemGray6.cgColor)
                    context.fill(CGRect(x: margeH, y: y, width: largeurContenu, height: 18))
                }
            }

            let montantAttrs = e.typeEcriture == .recette ? montantRecetteAttrs : montantDepenseAttrs
            let signe = e.typeEcriture == .recette ? "+" : "-"

            let colonnes: [String] = [
                dateFormatter.string(from: e.date),
                String(e.libelle.prefix(45)),
                e.centresDeCout.isEmpty ? "—" : e.centresDeCout.map(\.nom).joined(separator: ", "),
                e.typeTVANom.isEmpty ? "—" : e.typeTVANom,
                String(format: "%.1f%%", e.tauxTVA * 100),
                e.montantTVA.formatMonetaire,
                "\(signe)\(e.montantTTC.formatMonetaire)"
            ]

            for (i, texte) in colonnes.enumerated() {
                let alignment: NSTextAlignment = i >= 4 ? .right : .left
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = alignment

                var attrs = i == 6 ? montantAttrs : ligneAttrs
                attrs[.paragraphStyle] = paragraphStyle

                let rect = CGRect(x: colX[i] + (i >= 4 ? -4 : 4), y: y + 4, width: colW[i], height: 12)
                NSAttributedString(string: texte, attributes: attrs).draw(in: rect)
            }
            y += 18
        }

        // Totaux
        y += 10
        nouvellePageSiNecessaire(hauteurRequise: 60)

        if let context = UIGraphicsGetCurrentContext() {
            context.setStrokeColor(UIColor.systemGray3.cgColor)
            context.setLineWidth(0.5)
            context.move(to: CGPoint(x: margeH, y: y))
            context.addLine(to: CGPoint(x: margeH + largeurContenu, y: y))
            context.strokePath()
        }
        y += 10

        let boldAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 10),
            .foregroundColor: UIColor.black
        ]
        NSAttributedString(string: "Recettes : +\(totalRecettes.formatMonetaire)", attributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.systemGreen]).draw(at: CGPoint(x: margeH, y: y))
        y += 16
        NSAttributedString(string: "Dépenses : -\(totalDepenses.formatMonetaire)", attributes: [.font: UIFont.boldSystemFont(ofSize: 10), .foregroundColor: UIColor.systemRed]).draw(at: CGPoint(x: margeH, y: y))
        y += 16
        let solde = totalRecettes - totalDepenses
        NSAttributedString(string: "Solde : \(solde >= 0 ? "+" : "")\(solde.formatMonetaire)", attributes: boldAttrs).draw(at: CGPoint(x: margeH, y: y))
        y += 40

        // Dessin des deux récapitulatifs côte à côte
        let typesTVAAfficher = typesTVA.filter { $0.taux > 0 }
        let hauteurCentres = CGFloat(centres.count * 15 + 40)
        let hauteurTVA = CGFloat(typesTVAAfficher.count * 15 + 40)
        let hauteurRequise = max(hauteurCentres, hauteurTVA)

        nouvellePageSiNecessaire(hauteurRequise: hauteurRequise)

        let yDebutRecaps = y
        let xBlocGauche = margeH
        let xBlocDroit = margeH + 350
        let colTitreW: CGFloat = 180
        let colValW: CGFloat = 100

        let recapTitreAttrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 11),
            .foregroundColor: UIColor.black,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]

        // --- BLOC GAUCHE : Centres de coût ---
        if !centres.isEmpty {
            var yGauche = yDebutRecaps
            NSAttributedString(string: "Récapitulatif par centre de coût", attributes: recapTitreAttrs).draw(at: CGPoint(x: xBlocGauche, y: yGauche))
            yGauche += 20

            for centre in centres {
                let totalTTC = lignes
                    .filter { e in e.centresDeCout.contains { $0.id == centre.id } }
                    .reduce(0) { $0 + $1.montantSigne }

                NSAttributedString(string: "\(centre.nom) :", attributes: ligneAttrs).draw(at: CGPoint(x: xBlocGauche, y: yGauche))

                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .right
                var valAttrs = ligneAttrs
                valAttrs[.paragraphStyle] = paragraphStyle
                valAttrs[.foregroundColor] = totalTTC >= 0 ? UIColor.systemGreen : UIColor.systemRed

                let rect = CGRect(x: xBlocGauche + colTitreW, y: yGauche, width: colValW, height: 12)
                let signe = totalTTC >= 0 ? "+" : ""
                NSAttributedString(string: "\(signe)\(totalTTC.formatMonetaire)", attributes: valAttrs).draw(in: rect)
                yGauche += 15
            }
        }

        // --- BLOC DROIT : TVA ---
        if !typesTVAAfficher.isEmpty {
            var yDroit = yDebutRecaps
            NSAttributedString(string: "Récapitulatif TVA", attributes: recapTitreAttrs).draw(at: CGPoint(x: xBlocDroit, y: yDroit))
            yDroit += 20

            for type in typesTVAAfficher {
                let totalTVA = lignes
                    .filter { $0.typeTVANom == type.nom }
                    .reduce(0) { $0 + $1.montantTVA }

                NSAttributedString(string: "TVA \(type.nom) (\(String(format: "%.1f%%", type.taux * 100))) :", attributes: ligneAttrs).draw(at: CGPoint(x: xBlocDroit, y: yDroit))

                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.alignment = .right
                var valAttrs = ligneAttrs
                valAttrs[.paragraphStyle] = paragraphStyle

                let rect = CGRect(x: xBlocDroit + colTitreW, y: yDroit, width: colValW, height: 12)
                NSAttributedString(string: totalTVA.formatMonetaire, attributes: valAttrs).draw(in: rect)
                yDroit += 15
            }
        }

        UIGraphicsEndPDFContext()

        return url
    }
}
