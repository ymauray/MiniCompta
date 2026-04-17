# Spécifications — Mini Compta

## Contexte

Application iPhone personnelle pour remplacer un fichier Excel de comptabilité.

## Périmètre fonctionnel

### Journal d'écritures

- Saisie d'une écriture : date, libellé, type (recette / dépense), montant TTC, type TVA, catégorie, centre de coût
- Le montant HT et le montant TVA sont **calculés automatiquement** à partir du TTC et du taux
- Modification et suppression (swipe-to-delete dans la liste)
- Liste groupée par mois, avec totaux mensuels (recettes / dépenses) dans l'en-tête de section
- Recherche par libellé
- **Affichage optimisé** : libellé sur toute la largeur (ligne 1), date et montant (ligne 2), et pastilles de catégorie/centre de coût (ligne 3)

### Tableau de bord

- Navigation par mois (mois précédent / suivant, bouton désactivé pour le mois futur)
- Trois cartes : total recettes, total dépenses, solde
- Graphique en barres horizontales par centre de coût (Swift Charts)
- Graphique en donut par catégorie (Swift Charts) avec légende
  - **Annotation lisible** : les libellés sont affichés dans des pastilles contrastées (fond noir semi-transparent) pour une visibilité optimale sur tous les supports.
- Liste des 5 dernières écritures (tous mois confondus)

### Paramètres

- **Choix de la devise** : sélection de la devise d'affichage (EUR, CHF, USD, GBP, CAD, JPY).
- Gestion CRUD des centres de coût (nom + couleur, modification par tap sur la ligne)
- Gestion CRUD des catégories (nom + couleur, modification par tap sur la ligne)
- Gestion CRUD des types TVA (nom, taux, signification, modification par tap sur la ligne)
- **Tri manuel** par drag-and-drop pour toutes les listes de référence
- **Duplication rapide** d'un élément via swipe
- **Sauvegarde & Import (JSON)** : permet d'exporter l'intégralité des données de l'application ou de les restaurer depuis un fichier.
  - *Sécurité* : avertissement explicite sur la responsabilité de l'utilisateur lors de l'export.
  - *Validation* : confirmation critique avant l'importation (écrasement des données).
- **Réinitialisation** : option pour effacer toutes les données et remettre l'application à zéro (avec confirmation).
- Accès à l'export PDF

### Export PDF

- Sélection d'une période (date de début et de fin) avec **boutons de raccourcis rapides** (trimestre, année).
- Aperçu du nombre d'écritures et des totaux avant génération.
- Rapport **A4 Paysage** pour une lecture détaillée des colonnes (Date, Libellé, Centre, Type TVA, Taux, TVA, TTC).
- **Récapitulatifs synthétiques** : affiche côte à côte les totaux par centre de coût (TTC) et par type de TVA (pour les taux strictement positifs) pour la période choisie.
- Partage via feuille iOS (`UIActivityViewController`)

## Données de référence par défaut

### Initialisation automatique
Lors du premier lancement de l'application (et si aucune écriture n'existe), les données suivantes sont injectées automatiquement pour permettre une découverte immédiate de l'application :

1. **Types TVA** : Normal 20%, Réduit 5.5%, Exonéré 0%.
2. **Catégories** : Logiciel, Matériel, Services.
3. **Centres de coût** : Structure, Produit 1.
4. **Journal** : 7 écritures de démonstration réparties sur les 7 derniers jours (6 dépenses et 1 recette).

Un message d'information est affiché à l'utilisateur lors de cette première injection. Les données peuvent être modifiées ou supprimées dans les paramètres, ou l'application peut être remise à zéro via l'option de réinitialisation.

## Contraintes techniques

- **Plateforme** : iOS 18.0+, iPhone uniquement
- **Persistance** : SwiftData (base SQLite locale, pas de synchronisation cloud)
- **Devise** : configurable, locale courante du système pour les formats de nombre
- **Hors ligne** : 100% — aucune connexion réseau requise
- **Swift** : version 6.0, concurrence stricte

## Hors périmètre

- Synchronisation iCloud / multi-appareils
- Import depuis Excel ou CSV
- Comptabilité double entrée (grand livre, bilan)
- Notifications / rappels
� double entrée (grand livre, bilan)
- Notifications / rappels
