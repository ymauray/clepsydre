# AGENTS.md — consignes pour les agents de code

Clepsydre est une application iOS, iPadOS et watchOS de gestion du temps : chaque matin, quatre
objectifs assignés à quatre blocs de temps de durées différentes. [`SPECS.md`](SPECS.md) dit ce
que fait l'app et pourquoi elle ne fait pas le reste ; [`AVANCEMENT.md`](AVANCEMENT.md) suit
l'implémentation étape par étape.

## Structure

- `project.yml` : description du projet XcodeGen, **source de vérité** (iOS seul).
- `project-avec-montre.yml` : variante qui embarque l'app Watch, pour Xcode Cloud et la CI.
- `ClepsydreCore/` : Swift Package local partagé (modèle, décompte, notifications, dessin).
- `Clepsydre/` : app iOS et iPadOS (SwiftUI).
- `ClepsydreWatch/` : app watchOS.
- `ClepsydreActivites/` : extension WidgetKit (Live Activity du bloc en cours).
- `Tests/ClepsydreTests/` : tests d'intégration SwiftData.
- `docs/` : politique de confidentialité, publiée par GitHub Pages.

## Commandes

```sh
xcodegen generate                      # après toute modification de project.yml
cd ClepsydreCore && swift test         # tests du cœur, sans simulateur
```

## Règles

- Tout en français : code, commentaires, documentation, messages de commit.
- Ne jamais modifier le `.xcodeproj` à la main : modifier `project.yml`, régénérer avec
  `xcodegen generate`, puis committer le projet régénéré (Xcode Cloud en a besoin).
- La logique métier va dans `ClepsydreCore`, testable sans interface ; l'horloge est
  injectable (`Horloge`, `HorlogeFigee`) pour les tests.
- Ne pas incrémenter `CURRENT_PROJECT_VERSION` : Xcode Cloud le gère. Seule `MARKETING_VERSION`
  se maintient à la main dans `project.yml`.
- La release (TestFlight, App Store) passe par Xcode Cloud ; les workflows GitHub ne font que
  la qualité.
- Travailler sur une branche et ouvrir une PR vers `main` ; la CI `iOS CI` doit passer.
