# Spécifications — Mini Compta

## Contexte

Application iPhone personnelle pour remplacer un fichier Excel de comptabilité. Conçue pour la comptabilité suisse (monnaie CHF, taux TVA suisses).

## Périmètre fonctionnel

### Journal d'écritures

- Saisie d'une écriture : date, libellé, type (recette / dépense), montant TTC, type TVA, catégorie, centre de coût
- Le montant HT et le montant TVA sont **calculés automatiquement** à partir du TTC et du taux
- Modification et suppression (swipe-to-delete dans la liste)
- Liste groupée par mois, avec totaux mensuels (recettes / dépenses) dans l'en-tête de section
- Recherche par libellé

### Tableau de bord

- Navigation par mois (mois précédent / suivant, bouton désactivé pour le mois futur)
- Trois cartes : total recettes, total dépenses, solde
- Graphique en barres horizontales par centre de coût (Swift Charts)
- Graphique en donut par catégorie (Swift Charts) avec légende
- Liste des 5 dernières écritures (tous mois confondus)

### Paramètres

- Gestion CRUD des centres de coût (nom + couleur)
- Gestion CRUD des catégories (nom + couleur)
- Gestion CRUD des types TVA (nom, taux, signification, case formulaire)
- Accès à l'export PDF

### Export PDF

- Sélection d'une période (date de début et de fin)
- Aperçu du nombre d'écritures et des totaux avant génération
- Rapport A4 : en-tête, tableau des écritures, récapitulatif
- Partage via feuille iOS (`UIActivityViewController`)

## Données de référence par défaut

Les types TVA suivants sont pré-chargés au premier lancement :

| Nom | Taux | Case formulaire |
|---|---|---|
| Normal 8.1% | 8.1% | 302 |
| Spécial 2.6% | 2.6% | 342 |
| Exonéré 0% | 0% | — |

Les centres de coût et les catégories démarrent vides (tout est configurable).

## Contraintes techniques

- **Plateforme** : iOS 18.0+, iPhone uniquement
- **Persistance** : SwiftData (base SQLite locale, pas de synchronisation cloud)
- **Devise** : CHF, locale `fr_CH`
- **Hors ligne** : 100% — aucune connexion réseau requise
- **Swift** : version 6.0, concurrence stricte

## Hors périmètre

- Synchronisation iCloud / multi-appareils
- Import depuis Excel ou CSV
- Gestion multi-devises
- Comptabilité double entrée (grand livre, bilan)
- Notifications / rappels
