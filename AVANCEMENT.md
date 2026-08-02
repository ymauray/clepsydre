# Clepsydre — Avancement

Suivi d'implémentation de la v1. Les étapes sont dans l'ordre où il est logique de les
prendre : chacune s'appuie sur les précédentes. Le détail de ce qu'on construit est dans
[SPECS.md](SPECS.md), les renvois `§` pointent dessus.

## Légende

| Emoji | Statut |
|---|---|
| ⬜ | À faire |
| 🚧 | En cours |
| ✅ | Fait et vérifié |
| 🧊 | Reporté — pas maintenant, mais toujours prévu en v1 |
| ⏭️ | Renvoyé en v2 |
| ❌ | Abandonné |
| ⛔ | Bloqué — voir la note |

---

## Phase 0 — Fondations

| | Étape | Note |
|---|---|---|
| ✅ | Spécifications rédigées et questions tranchées | SPECS.md §1–9 |
| ✅ | `project.yml` XcodeGen (fr, Info.plist généré, 4 orientations, Team ID) | §8.1 |
| ✅ | Package local `ClepsydreCore` (iOS + watchOS) | §8 |
| ✅ | Modèles `Bloc`, `Objectif`, `Reglages` | §4 |
| ✅ | Horloge injectable (`Horloge`, `HorlogeFigee`) | §8.4 |
| ✅ | Logique de décompte par dates absolues | §6 |
| ✅ | Règles de journée (timer unique, ordre libre, bascule de jour) | §5.2, §5.4, §9 |
| ✅ | 38 tests unitaires au vert | §8.4 |
| ✅ | Chaîne de build validée sur iPhone physique | tests + install + lancement |
| ✅ | Dépôt git initialisé et poussé | `github.com/ymauray/clepsydre` |

## Phase 1 — L'écran principal

C'est le cœur de l'app : si cette phase est réussie, l'app est déjà utilisable.

| | Étape | Note |
|---|---|---|
| ✅ | Grille des quatre blocs, 2×2 en portrait | §7.1 |
| ✅ | Bascule vers une rangée de 4 en paysage | §7.1 |
| ✅ | Tap pour lancer / mettre en pause | §5.2 |
| ✅ | Temps restant en `min:sec` | §2, §7 |
| ✅ | Remplissage du carré qui monte | §7 |
| ✅ | Une couleur par bloc (terre cuite, ambre, sauge, prune) | §7.3 |
| ✅ | Appui long → renommer l'objectif, ajuster la durée | §5.2 |
| ✅ | Échelle des durées : 1, 5, 10, 15… | §4, `EchelleDesDurees` |
| ✅ | Direction visuelle passée en revue sur l'appareil | typographie, couleurs, respirations |
| ✅ | Bloc actif mis en évidence par une bordure teintée de 3 pt | retour d'usage |
| ✅ | Trappe de développement conservée | 4 taps rapides = remise à zéro ; `#if DEBUG` l'exclut du build Release |
| ✅ | État `termine` : aplat plein, texte en négatif, durée accomplie | §5.3, §3 |
| ✅ | Carrés au plus grand : marge unique de 20 pt, tout le reste aux blocs | §7.1 |
| ✅ | Transition animée portrait ↔ paysage | vérifiée sur iPhone |
| ✅ | En-tête : titre serif + clepsydre vectorielle à l'heure du jour | §7.2 |
| ✅ | Tailles iPad vérifiées (simulateur iPad Pro 13") | carrés ~480 pt en portrait, ~320 pt en paysage |

## Phase 2 — Le rituel du matin

| | Étape | Note |
|---|---|---|
| ✅ | Écran de saisie des quatre objectifs, avec la durée du bloc en regard | §5.1 |
| ✅ | Étape passable : bouton « Plus tard », rien d'obligatoire | §5.1 |
| ✅ | Proposé à la première ouverture de la journée, une fois par jour | §5.1 |
| ✅ | Ouvert directement depuis la notification matinale | §5.1, `RouteurDeNotifications` |
| ✅ | Les notifications restent visibles app ouverte | bandeau + son au premier plan |
| ✅ | Plantage à l'ouverture depuis la notification corrigé | handler de complétion appelé hors du thread principal, §8.3 |
| ✅ | Retour haptique sur la trappe des 4 taps | `UIImpactFeedbackGenerator` préparé, motif double |

## Phase 3 — Notifications

| | Étape | Note |
|---|---|---|
| ✅ | Programmation à la fin d'un bloc, annulation à la pause | §6 |
| ✅ | Rappel matinal récurrent à 8h00 | §5.1 |
| ✅ | Autorisation demandée au premier timer lancé ou aux objectifs validés | §5.5 |
| ✅ | Notification de fin de bloc vérifiée sur l'appareil | reçue app en arrière-plan |
| ✅ | Rappel matinal vérifié sur l'appareil | `rappel-matinal — chaque jour à 08h00`, lu via `--console` |
| 🧊 | Icône absente des notifications, sur l'iPhone seulement | présente sur iPad → cache local de l'iPhone, pas un défaut de configuration ; à revoir après un redémarrage |
| ✅ | Refus d'autorisation géré | l'app fonctionne et se tait ; aucune relance, aucun bandeau (§5.5) |

## Phase 4 — Réglages

| | Étape | Note |
|---|---|---|
| ✅ | Stockage des réglages (durées globales, rappel matinal) | §4, §9 |
| ⬜ | Écran de réglages : les quatre durées, notifications, heure du rappel | §4 |

## Phase 5 — watchOS

| | Étape | Note |
|---|---|---|
| ✅ | Cible watchOS et vue d'un bloc plein écran | §3.1 |
| ✅ | Balayage horizontal + indicateur de page | §7.1 |
| ✅ | Ouverture sur le bloc en cours, sinon le premier non terminé | §7.1 |
| ⛔ | Compiler et lancer sur l'Apple Watch | SDK watchOS non installé sur la machine |
| ⬜ | Synchronisation iPhone ↔ Watch (`WatchConnectivity`) | §8, l'iPhone fait autorité |
| ⬜ | Notification de fin de bloc sur la montre | §3.1 |
| ⬜ | Défilement à la couronne digitale | §7.1 |

## Phase 6 — Finition

| | Étape | Note |
|---|---|---|
| ⬜ | VoiceOver : relire les libellés d'état de chaque bloc | §7 |
| ⬜ | Dynamic Type jusqu'aux grandes tailles | §7 |
| ✅ | Thème sombre, persistant, bascule au double tap sur le titre | §7.3 |
| ✅ | Icône de l'app, générée depuis le dessin de la clepsydre | `swift run IcôneClepsydre <chemin.png> [heure]` |
| ⬜ | Icône watchOS (cercle, autre cadrage) | même générateur à adapter |
| ⬜ | Passage à minuit vérifié pour de vrai (app ouverte comme fermée) | §5.4 |
| ⬜ | Comportement au changement de fuseau horaire | à décider |

## Renvoyé en v2

Rappel de ce qu'on ne fait **pas**, pour ne pas y revenir par accident (§3) :

| | Sujet |
|---|---|
| ⏭️ | Réinitialisation d'un timer |
| ⏭️ | Marquage manuel d'un objectif comme accompli |
| ⏭️ | Historique et statistiques |
| ⏭️ | Synchronisation iCloud multi-appareils |
| ⏭️ | Widgets, Live Activities |
| ⏭️ | Sons personnalisés, thèmes de couleurs (au-delà du clair / sombre) |
| ⏭️ | Tags, projets, récurrence, sous-tâches |
| ⏭️ | Compte utilisateur, backend |
