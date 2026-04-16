# Mini Compta

Application iPhone de comptabilité personnelle simple, conçue pour la Suisse (TVA CHF).

## Fonctionnalités

- **Journal d'écritures** — saisie de recettes et dépenses avec calcul automatique TVA (HT, TVA, TTC)
- **Tableau de bord** — vue mensuelle avec graphiques par centre de coût et par catégorie
- **Paramètres configurables** — centres de coût, catégories et types TVA entièrement personnalisables
- **Export PDF** — génération d'un rapport sur une période choisie, partageable via iOS

## Prérequis

| Outil | Version minimale |
|---|---|
| Xcode | 16.0 |
| iOS (cible) | 18.0 |
| Swift | 6.0 |
| XcodeGen | 2.x |

## Démarrage

```bash
# 1. Cloner le dépôt
git clone <url>
cd MaCompta

# 2. Générer le projet Xcode
xcodegen generate

# 3. Ouvrir dans Xcode
open MaCompta.xcodeproj
```

Lancer ensuite sur simulateur ou appareil via Xcode (⌘R).

## Structure du projet

```
Sources/
├── Models/           — modèles SwiftData (Ecriture, CentreDeCout, Categorie, TypeTVA)
├── Stores/           — logique métier @Observable (JournalStore, ParametresStore)
├── Views/
│   ├── Dashboard/    — tableau de bord et graphiques
│   ├── Journal/      — liste et formulaire de saisie
│   ├── Parametres/   — gestion des listes de référence
│   └── Export/       — génération PDF
└── Assets.xcassets   — icône et ressources visuelles
```

## Conventions

- Commits : [Conventional Commits](https://www.conventionalcommits.org/) en français
- Pas de force unwrap (`!`) — utiliser `guard let` / `if let`
- Mutations d'état uniquement via les Stores (`@Observable`)
- Aucune logique métier dans les vues SwiftUI
