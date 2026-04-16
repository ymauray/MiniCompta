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
│   JournalStore · ParametresStore    │
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
Listes de référence configurables. Chacune porte un `nom` et une `couleurHex` (ex. `#5E9BF0`). Relation inverse avec `Ecriture` (deleteRule `.nullify`).

### `TypeTVA`
Taux TVA suisses avec métadonnées pour la déclaration.

| Propriété | Description |
|---|---|
| `nom` | Libellé affiché |
| `taux` | Valeur décimale (0.081, 0.026, 0.0) |
| `signification` | Description du taux |
| `caseFormulaire` | N° de case du formulaire TVA suisse |

Trois entrées sont injectées au premier lancement (seed) : 8.1%, 2.6%, 0%.

## Stores

### `JournalStore`
- Lecture des écritures (toutes, filtrées par mois)
- Calculs de totaux : recettes, dépenses, solde mensuel
- Agrégats pour graphiques : par centre de coût, par catégorie
- CRUD : `ajouterEcriture`, `supprimerEcriture`, `sauvegarder`

### `ParametresStore`
- CRUD pour `TypeTVA`, `CentreDeCout`, `Categorie`
- Seed automatique des types TVA au premier lancement

> Les vues utilisent directement `@Query` de SwiftData pour les listes simples (performances optimales). Les Stores sont réservés aux opérations avec logique ou calculs.

## Navigation

`ContentView` est un `TabView` à 3 onglets :

1. **Tableau de bord** (`TableauDeBordView`) — graphiques Swift Charts, navigation mensuelle
2. **Journal** (`JournalView`) → `EcritureFormView` (ajout / modification)
3. **Paramètres** (`ParametresView`) → listes configurables + export PDF

## Export PDF

`ExportPDFView` utilise **PDFKit** (Core Graphics) pour générer un rapport A4 :
- En-tête avec période
- Tableau des écritures (date, libellé, type, TVA, montant)
- Totaux récapitulatifs (recettes / dépenses / solde)
- Partagé via `UIActivityViewController`

## Icône

L'icône est générée programmatiquement par `GenerateIcon.swift` (script Swift autonome, AppKit + Core Graphics). Lancer `swift GenerateIcon.swift` à la racine pour régénérer un PNG 1024×1024.
