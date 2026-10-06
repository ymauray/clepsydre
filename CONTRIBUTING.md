# Contribuer à Clepsydre

Merci de vous intéresser à Clepsydre ! Ce document résume comment proposer une contribution.

## Avant de commencer

Clepsydre fait volontairement peu de choses : [`SPECS.md`](SPECS.md) explique ce que fait l'app
et pourquoi elle ne fait pas le reste. Pour une nouvelle fonctionnalité ou un changement
important, ouvrez d'abord une issue ou une [discussion](https://github.com/ymauray/clepsydre/discussions)
pour en parler avec le mainteneur.

## Environnement de développement

Prérequis : un Mac avec Xcode (Swift 6), [XcodeGen](https://github.com/yonaskolb/XcodeGen)
(`brew install xcodegen`).

```sh
xcodegen generate                      # régénérer le projet après une modification de project.yml
cd ClepsydreCore && swift test         # tests du cœur, sans simulateur
```

Le `.xcodeproj` est généré depuis `project.yml` : modifiez `project.yml`, jamais le projet à la
main, puis régénérez **et committez** le projet. Voir le [README](README.md) pour les deux
descriptions de projet (`project.yml` et `project-avec-montre.yml`).

## Proposer une modification

1. Créez une branche dédiée depuis `main` (ex. `fix/...`, `feature/...`).
2. Faites des commits atomiques, avec des messages clairs.
3. Vérifiez que les tests passent en local.
4. Ouvrez une pull request vers `main` en remplissant le modèle fourni. La CI (`iOS CI`) doit
   passer ; les PR sont mergées en squash.

La logique métier (décompte, règles de la journée, notifications) va dans `ClepsydreCore`, où
elle se teste sans interface. Le code, les commentaires et la documentation sont en français.
