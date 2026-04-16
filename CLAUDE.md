# CLAUDE.md

## Workflow obligatoire

Après toute modification de `project.yml`, exécuter :

```bash
xcodegen generate
```

## Conventions de code

- Pas de `!` (force unwrap) — utiliser `guard let` ou `if let`
- Les mutations d'état passent par un Store (`@Observable`)
- Pas de logique métier dans les vues SwiftUI

## Commits

Convention : Conventional Commits, messages en français.

Exemples :
- `feat: ajouter l'écran de connexion`
- `fix: corriger le crash au démarrage`
- `refactor: extraire la logique dans un Store`

## SourceKit

Les faux positifs SourceKit (erreurs dans l'éditeur après génération) se résolvent
en fermant et rouvrant le projet Xcode, ou en relançant `xcodegen generate`.