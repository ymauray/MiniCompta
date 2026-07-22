# Mini Compta

Application iPhone de comptabilité personnelle simple.

## Fonctionnalités

- **Journal d'écritures** — saisie de recettes et dépenses avec calcul automatique TVA (HT, TVA, TTC), affectation à un ou plusieurs centres de coût
- **Tableau de bord** — vue par période (mois, trimestre ou année) avec graphiques par centre de coût et par catégorie
- **Paramètres configurables** — centres de coût, catégories et types TVA entièrement personnalisables
- **Sauvegarde & Restauration** — export/import JSON pour sécuriser ses données et réinitialisation complète
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
cd MiniCompta

# 2. Générer le projet Xcode
xcodegen generate

# 3. Ouvrir dans Xcode
open MiniCompta.xcodeproj
```

Lancer ensuite sur simulateur ou appareil via Xcode (⌘R).

## Structure du projet

```
Sources/
├── Models/           — modèles SwiftData (Ecriture, CentreDeCout, Categorie, TypeTVA)
├── Stores/           — logique métier @Observable (JournalStore, ParametresStore)
├── Services/         — services réutilisables (GenerateurPDF)
├── Views/
│   ├── Dashboard/    — tableau de bord, graphiques et export PDF
│   ├── Journal/      — liste, détail, formulaire de saisie
│   ├── Parametres/   — gestion des listes de référence
│   └── Shared/       — composants partagés (ShareSheet)
└── Assets.xcassets   — icône et ressources visuelles
```

## Conventions

- Commits : [Conventional Commits](https://www.conventionalcommits.org/) en français
- Branche `main` protégée (Pull Request + CI obligatoires)
- Pas de force unwrap (`!`) — utiliser `guard let` / `if let`
- Mutations d'état uniquement via les Stores (`@Observable`)
- Aucune logique métier dans les vues SwiftUI

## Cycle de développement et release

### Branches

- `main` est la branche stable. Chaque version livrée y est marquée par un **tag** (`v1.1`, `v1.2`, …).
- Le développement d'une version se fait sur une **branche dédiée** (`v1.2`, `v1.3`, …) créée depuis `main`.
- Le numéro de **version marketing** (`MARKETING_VERSION` dans `project.yml`) est incrémenté **dès le début du cycle** sur la branche de version.

### Intégration continue — GitHub Actions

Les workflows GitHub **ne font pas la release**. Ils servent uniquement à :

- **Assurer la qualité** — le workflow `iOS CI` (`.github/workflows/ios.yml`) compile le projet et exécute les tests unitaires sur simulateur à chaque push et pull request.
- **Déployer la politique de confidentialité** — via GitHub Pages (workflow intégré « pages-build-deployment », donc absent du dépôt), à partir du dossier [`docs/`](docs/) de `main` → https://ymauray.github.io/MiniCompta/

### Release — Xcode Cloud

La **livraison sur TestFlight et l'App Store est assurée par Xcode Cloud** (configuré côté App Store Connect, pas dans le dépôt).

- Le **numéro de build** (`CURRENT_PROJECT_VERSION`) est **géré automatiquement par Xcode Cloud** — inutile de l'incrémenter à la main.
- Seule la **version marketing** (`MARKETING_VERSION`) est maintenue manuellement dans `project.yml` ; elle doit être strictement supérieure à la version en production.
- `CFBundleShortVersionString` / `CFBundleVersion` référencent ces build settings dans `Sources/Info.plist` (`$(MARKETING_VERSION)` / `$(CURRENT_PROJECT_VERSION)`) — ne pas y remettre de valeurs codées en dur.
