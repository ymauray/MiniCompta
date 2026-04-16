# Contribuer à Mini Compta

## Workflow

1. Créer une branche depuis `main`
2. Faire vos modifications
3. Lancer `xcodegen generate` si vous avez modifié `project.yml`
4. Vérifier que le projet compile (`⌘B` dans Xcode ou `xcodebuild`)
5. Créer une Pull Request vers `main`

## Conventions de commits

Ce projet utilise [Conventional Commits](https://www.conventionalcommits.org/) en **français**.

```
feat: ajouter le filtrage par catégorie dans le journal
fix: corriger le calcul TVA lorsque le taux est nul
refactor: extraire la logique de tri dans JournalStore
docs: mettre à jour ARCHITECTURE.md
chore: régénérer le projet Xcode
```

## Règles de code

- **Pas de `!`** (force unwrap) — utiliser `guard let` ou `if let`
- **Pas de logique métier dans les vues** — tout passe par un Store `@Observable`
- **SwiftData** pour la persistance — pas de stockage UserDefaults pour les données métier
- **Swift 6** — pas de `@unchecked Sendable`, résoudre les warnings de concurrence

## Régénérer l'icône

```bash
swift GenerateIcon.swift
```

Modifiez `GenerateIcon.swift` à la racine pour changer le design, puis exécutez le script. Le PNG 1024×1024 est placé automatiquement dans `Sources/Assets.xcassets/AppIcon.appiconset/`.

## Régénérer le launch screen

```bash
swift GenerateLaunchScreen.swift
```

Modifiez `GenerateLaunchScreen.swift` à la racine. Le PNG 1290×2796 est placé dans `Sources/Assets.xcassets/LaunchImage.imageset/`. Après mise à jour, supprimer l'app du simulateur/appareil pour contourner le cache iOS.

## Après modification de `project.yml`

```bash
xcodegen generate
```

Les faux positifs SourceKit qui apparaissent après la génération se résolvent en fermant et rouvrant le projet Xcode.
