# Clepsydre

Une application iOS et watchOS de gestion du temps, construite autour d'un rituel quotidien :
chaque matin, **quatre objectifs** pour la journée, assignés à **quatre blocs de temps** de
durées différentes.

Pas de listes infinies, pas de projets, pas de sous-tâches. Quatre choses, quatre durées,
une journée.

- [`SPECS.md`](SPECS.md) — ce que fait l'app, et surtout **pourquoi** elle ne fait pas le reste
- [`AVANCEMENT.md`](AVANCEMENT.md) — où en est l'implémentation, étape par étape
- [Politique de confidentialité](https://ymauray.github.io/clepsydre/) — aucune donnée ne quitte l'appareil

## Structure

```
project.yml            description du projet, source de vérité (XcodeGen)
ClepsydreCore/         Swift Package local — modèle, décompte, notifications, dessin
Clepsydre/             application iOS et iPadOS (SwiftUI)
ClepsydreWatch/        application watchOS
ClepsydreActivites/    extension WidgetKit — Live Activity du bloc en cours
Tests/ClepsydreTests/  tests d'intégration SwiftData
docs/                  politique de confidentialité, publiée par GitHub Pages
```

L'essentiel de la logique vit dans `ClepsydreCore`, partagé par les deux applications : le
décompte, les règles de la journée et la programmation des notifications s'y testent sans
interface, sans simulateur et sans appareil.

## Développer

```sh
xcodegen generate                      # régénérer le projet après une modification de project.yml
cd ClepsydreCore && swift test         # la boucle rapide : tout le cœur, en quelques millisecondes
```

### Deux descriptions de projet

| Fichier | Usage |
|---|---|
| `project.yml` | le quotidien sur le Mac — **iOS seul**, compile sans le SDK watchOS |
| `project-avec-montre.yml` | Xcode Cloud et l'intégration continue — **app Watch embarquée** |

Une app watchOS se livre à l'intérieur du bundle iOS. Mais l'embarquer rend la cible iOS
dépendante de la cible watchOS, donc impossible à compiler sans le SDK watchOS — absent de la
machine de développement. La variante n'ajoute que cette dépendance, tout le reste est hérité
par `include:`, il n'y a rien à tenir en double.

Xcode Cloud régénère le projet à partir de la variante via
[`ci_scripts/ci_post_clone.sh`](ci_scripts/ci_post_clone.sh), exécuté après le clonage.
**Le projet committé reste celui d'iOS seul.**

Le `.xcodeproj` est **généré** par XcodeGen : on modifie `project.yml`, jamais le projet à la
main. Il est malgré tout **committé**, parce qu'Xcode Cloud a besoin de trouver le projet et
son schéma partagé dans le dépôt pour configurer un workflow. Après toute modification de
`project.yml`, régénérer **et committer** le projet.

Le développement se fait sur appareil physique plutôt qu'au simulateur :

```sh
xcodebuild -project Clepsydre.xcodeproj -scheme Clepsydre \
  -destination 'platform=iOS,name=<appareil>' -allowProvisioningUpdates test
```

## Cycle de développement et release

### Intégration continue — GitHub Actions

Les workflows GitHub **ne font pas la release**. Ils servent uniquement à :

- **Assurer la qualité** — le workflow [`iOS CI`](.github/workflows/ios.yml) exécute les
  tests du module partagé, compile et teste l'application iOS sur simulateur, et compile la
  cible watchOS, à chaque push et pull request sur `main`.
- **Déployer la politique de confidentialité** — via GitHub Pages (workflow intégré
  « pages-build-deployment », donc absent du dépôt), à partir du dossier [`docs/`](docs/) de
  `main` → https://ymauray.github.io/clepsydre/

### Release — Xcode Cloud

La **livraison sur TestFlight et l'App Store est assurée par Xcode Cloud** (configuré côté
App Store Connect, pas dans le dépôt).

- Le **numéro de build** (`CURRENT_PROJECT_VERSION`) est **géré automatiquement par Xcode
  Cloud** — inutile de l'incrémenter à la main.
- Seule la **version marketing** (`MARKETING_VERSION`) est maintenue manuellement dans
  `project.yml` ; elle doit être strictement supérieure à la version en production.
- L'`Info.plist` est **généré** à partir des build settings (`GENERATE_INFOPLIST_FILE`) :
  il n'y a aucun fichier où des numéros de version pourraient être codés en dur.
