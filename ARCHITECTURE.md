# Architecture — Mini Compta

## Vue d'ensemble

L'application suit une architecture en couches strictes : les vues SwiftUI ne contiennent pas de logique métier. Tout passe par des **Stores** `@Observable` qui s'appuient sur un contexte **SwiftData**.

```
┌─────────────────────────────────────┐
│            Vues SwiftUI             │
│  (TabView → Dashboard / Journal /   │
│   Paramètres / Export)              │
└────────────────┬────────────────────┘
                 │ lit / écrit via
┌────────────────▼────────────────────┐
│          Stores @Observable         │
│  JournalStore · ParametresStore     │
│  DeviseStore                        │
└────────────────┬────────────────────┘
                 │ ModelContext
┌────────────────▼────────────────────┐
│           SwiftData                 │
│  Ecriture · CentreDeCout ·          │
│  Categorie · TypeTVA                │
└─────────────────────────────────────┘
```

## Modèles de données

### `Ecriture`
Représente une ligne du journal comptable.

| Propriété | Type | Description |
|---|---|---|
| `date` | `Date` | Date de l'opération |
| `libelle` | `String` | Description libre |
| `typeEcriture` | `TypeEcriture` | `.recette` ou `.depense` |
| `montantTTC` | `Double` | Montant toutes taxes comprises |
| `tauxTVA` | `Double` | Taux (ex. 0.081 pour 8.1%) |
| `montantHT` | `Double` | **Calculé** : TTC / (1 + taux) |
| `montantTVA` | `Double` | **Calculé** : TTC − HT |
| `centreDeCout` | `CentreDeCout?` | Relation optionnelle |
| `categorie` | `Categorie?` | Relation optionnelle |
| `typeTVANom` | `String` | Nom du type TVA (dénormalisé) |

### `CentreDeCout` / `Categorie`
Listes de référence configurables. Chacune porte un `nom`, une `couleurHex` (ex. `#5E9BF0`) et un `ordre` (entier pour le tri manuel). Relation inverse avec `Ecriture` (deleteRule `.nullify`).

### `TypeTVA`
Taux TVA suisses avec métadonnées pour la déclaration.

| Propriété | Description |
|---|---|
| `nom` | Libellé affiché |
| `taux` | Valeur décimale (0.081, 0.026, 0.0) |
| `signification` | Description du taux |
| `caseFormulaire` | N° de case du formulaire TVA suisse |
| `ordre` | Position dans la liste (tri manuel) |

Trois entrées sont injectées au premier lancement (seed) : 8.1%, 2.6%, 0%.

## Stores

### `JournalStore`
- Lecture des écritures (toutes, filtrées par mois)
- Calculs de totaux : recettes, dépenses, solde mensuel
- Agrégats pour graphiques : par centre de coût, par catégorie
- CRUD : `ajouterEcriture`, `supprimerEcriture`, `sauvegarder`

### ParametresStore
- CRUD pour `TypeTVA`, `CentreDeCout`, `Categorie`
- Seed automatique des types TVA au premier lancement
- Tri des éléments selon leur propriété `ordre`

### `DeviseStore`
- Gère la devise de l'application (EUR, CHF, USD, etc.)
- Persistance du code devise dans `UserDefaults`
- Fournit le symbole de la devise pour les formateurs numériques

> Les vues utilisent directement `@Query` de SwiftData pour les listes simples (performances optimales). Les Stores sont réservés aux opérations avec logique ou calculs.

## Navigation

`ContentView` est un `TabView` à 3 onglets :

1. **Tableau de bord** (`TableauDeBordView`) — graphiques Swift Charts, navigation mensuelle
2. **Journal** (`JournalView`) → `EcritureFormView` (ajout / modification)
   - Les écritures sont affichées sur 3 lignes : libellé (gras), date/montant, et pastilles (badges).
3. **Paramètres** (`ParametresView`) → choix de la devise + listes configurables + export PDF
   - Supporte la réorganisation manuelle (drag-and-drop) et la duplication (swipe).

## Export PDF

`ExportPDFView` utilise **PDFKit** (Core Graphics / UIKit) pour générer un rapport **A4 en format Paysage** :
- En-tête avec période sélectionnée.
- Tableau détaillé des écritures (date, libellé, centre, type TVA, taux, montant TVA, montant TTC).
- Raccourcis de sélection rapide de période (trimestre, année en cours, année précédente).
- Totaux récapitulatifs (recettes / dépenses / solde).
- **Récapitulatifs détaillés** : les totaux par Centre de coût et par Type de TVA sont affichés côte à côte en fin de document pour une lecture synthétique.
- Partagé via `UIActivityViewController`.

## Icône

L'icône est générée programmatiquement par `GenerateIcon.swift` (script Swift autonome, AppKit + Core Graphics). Lancer `swift GenerateIcon.swift` à la racine pour régénérer un PNG 1024×1024.

## Launch screen et Splash screen

Le démarrage de l'application se décompose en deux phases pour une expérience fluide :

1. **Launch Screen natif** : utilise un `LaunchScreen.storyboard` qui affiche l'asset **`LaunchImage`** (généré par `GenerateLaunchScreen.swift` en 1290×2796 px) en mode `scaleAspectFill`.
2. **Splash Screen SwiftUI** : la `SplashView` prend immédiatement le relais en affichant le même asset `LaunchImage` avec les mêmes paramètres de rendu. Cela prolonge l'identité visuelle de 2 secondes avant la transition vers les onglets.

> **Cohérence visuelle** : l'utilisation d'un asset unique partagé entre le Storyboard et SwiftUI garantit une transition invisible, évitant tout décalage de positionnement ou de rendu par rapport à un dessin programmatique.
