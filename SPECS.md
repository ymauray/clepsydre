# Clepsydre — Spécifications

> Une clepsydre est une horloge à eau : le temps s'écoule, visiblement, sans qu'on
> puisse le retenir. C'est l'esprit de l'app.

## 1. Intention

Une application de productivité minimaliste, construite autour d'un rituel quotidien
simple : chaque matin, on définit **quatre objectifs** pour la journée, on les assigne
à **quatre blocs de temps** de durées différentes, et on les exécute.

Pas de listes infinies, pas de projets, pas de sous-tâches. Quatre choses, quatre
durées, une journée.

## 2. Principes de conception

- **Contrainte assumée** — exactement quatre blocs. La limite est la fonctionnalité.
- **Zéro friction** — un tap pour lancer, un tap pour mettre en pause.
- **Le temps est visible** — l'écoulement se lit d'un coup d'œil grâce au remplissage du bloc,
  doublé du temps restant en clair (`min:sec`) pour qui veut le chiffre exact.
- **Rien à configurer pour démarrer** — les durées par défaut fonctionnent dès l'installation.
- **Pas de culpabilisation** — un objectif non terminé n'est pas un échec affiché.

## 3. Périmètre de la v1

### Inclus

- Définition de 4 objectifs quotidiens (titre en texte libre)
- 4 timers à durées configurables (défaut : 5, 15, 30, 45 minutes)
- Assignation d'un objectif à un timer
- Lancer / mettre en pause un timer
- Décompte fiable même app en arrière-plan ou fermée
- Notification à la fin d'un timer
- Rappel matinal pour définir les objectifs du jour
- Application watchOS compagnon (voir §3.1)

### Explicitement hors périmètre (v1)

- Réinitialisation d'un timer
- Marquage manuel d'un objectif comme accompli
- Historique et statistiques
- Synchronisation iCloud / multi-appareils (hors iPhone ↔ Watch)
- Widgets, Live Activities
- Sons personnalisés, thèmes de couleurs (le clair / sombre, lui, est en v1 — §7.3)
- Tags, projets, récurrence, sous-tâches
- Compte utilisateur, backend

Ces points sont des candidats pour une v2, pas des oublis.

**Pourquoi pas de « accompli »** — un bloc mené à son terme *est* l'accomplissement. Si on
s'est donné 30 minutes pour lire, on va au bout ; si l'objectif tombe plus vite que prévu,
on utilise le temps restant à autre chose d'utile. La complétion du timer suffit, une case
à cocher en plus ne dirait rien de neuf.

**Pourquoi pas de réinitialisation** — la durée d'un bloc est un **minimum qu'on s'impose**,
pas un quota à remplir. Se donner 30 minutes de lecture et en faire 45, c'est parfaitement
dans l'esprit. Le bouton « réinitialiser », lui, sert à une seule chose en pratique : « j'en
ai marre de lire au bout de 3 minutes, j'efface et je fais autre chose ». C'est exactement
ce que l'app existe pour ne pas encourager. On peut mettre en pause, on ne peut pas effacer
la trace.

*(Une trappe existe pendant le développement : quatre taps rapides sur un bloc le remettent
à zéro, pour ne pas attendre 45 minutes en testant. Elle rejoue aussi le rappel du matin dix
secondes plus tard et oublie qu'on a déjà proposé le rituel, de quoi refaire le parcours
« notification → rituel » (§5.1) à volonté. Elle est compilée sous `#if DEBUG` —
modèle compris — donc le code n'existe tout simplement pas dans un build Release. Elle reste
en place : c'est le compilateur qui garantit son absence de l'app livrée, pas notre
vigilance.)*

### 3.1 watchOS

L'app Watch est pensée dès la v1, pas ajoutée après coup :

- Affichage d'un bloc à la fois, balayage horizontal pour passer au suivant (voir §7.1)
- Lancement / pause d'un bloc depuis le poignet
- Notification de fin de timer sur la montre
- Saisie des objectifs : **iPhone uniquement** (la montre consulte et pilote, elle ne rédige pas)

L'état est partagé entre les deux appareils ; l'iPhone reste la source de vérité.
Conséquence architecturale : le modèle et la logique de décompte vivent dans un **module
partagé** utilisé par les deux cibles, et l'UI seule est spécifique à chaque plateforme.

## 4. Modèle de données

### `Objectif`
| Champ | Type | Note |
|---|---|---|
| `id` | UUID | |
| `titre` | String | texte libre, court |
| `date` | Date | jour auquel il appartient (normalisé à minuit) |
| `position` | Int | 0…3, l'emplacement occupé |

Pas de champ `accompli` : l'accomplissement se lit dans l'état du bloc associé (voir §3).

### `Bloc` (timer)
| Champ | Type | Note |
|---|---|---|
| `id` | UUID | |
| `position` | Int | 0…3 |
| `duree` | TimeInterval | configurable par l'utilisateur |
| `tempsEcoule` | TimeInterval | progression persistée |
| `etat` | Enum | `enAttente` / `enCours` / `enPause` / `termine` |
| `dateDemarrage` | Date? | horodatage du dernier départ, pour le calcul en arrière-plan |

L'état `termine` est atteint uniquement quand le temps est écoulé, et il est définitif pour
la journée : aucune transition ne ramène un bloc en arrière.

### `Reglages`
- Les quatre durées, globales et valables tous les jours (défaut 5 / 15 / 30 / 45 min).
  Réglables selon l'échelle **1, 5, 10, 15… jusqu'à 180 minutes** : la minute isolée sert de
  plus petit cran, au-delà on raisonne en multiples de 5. Un pas de 5 partant de 1 donnerait
  1, 6, 11 — des durées qu'on ne se fixe jamais.
- Notifications de fin de timer activées ou non
- Rappel matinal activé ou non, et son heure (défaut 8h00)
- Jour de la dernière proposition du rituel, pour ne le proposer qu'une fois par jour
- Thème clair ou sombre, non renseigné tant qu'on suit le système (§7.3)

## 5. Parcours utilisateur

### 5.1 Le rituel du matin

À la première ouverture de la journée, l'app propose de définir les quatre objectifs.
Un champ de saisie par emplacement, avec la durée du bloc affichée à côté — ce qui
aide à choisir quel objectif va où.

L'étape est **passable** : un bouton « Plus tard » ferme l'écran sans rien exiger. On peut
lancer un timer sans avoir nommé son objectif et le nommer ensuite, par appui long sur son
bloc.

L'écran n'est proposé qu'**une fois par jour** — à la première ouverture, qu'on le remplisse
ou qu'on le passe. Revenir dans l'app dix fois dans la journée ne le fait pas réapparaître :
ce serait une relance, donc un reproche.

Chaque emplacement montre la **couleur et la durée** de son bloc, puisque c'est ce qui aide à
décider quel objectif va où. Les titres ne sont écrits dans le modèle qu'à la fermeture de
l'écran.

Une **notification locale est programmée chaque matin à 8h00** (heure configurable) avec un
message court et encourageant, pour inviter à poser les quatre objectifs du jour. Un tap
ouvre directement l'écran de saisie. Le ton reste celui du reste de l'app : une invitation,
jamais un reproche — et la notification ne se répète pas si elle est ignorée.

### 5.2 L'écran principal

Les quatre blocs, présentés ensemble sur iPhone et iPad (un seul à la fois sur la Watch —
voir §7.1 pour les mises en page). Chacun affiche :
- le titre de l'objectif (ou une invite discrète s'il est vide)
- la durée totale du bloc
- le temps restant en `min:sec`, si le bloc est en cours ou en pause
- une représentation visuelle de l'écoulement (remplissage du bloc)

Un tap sur un bloc lance ou met en pause son timer. Un **appui long** permet de renommer son
objectif, sans interrompre ce qui tourne — et rien d'autre : la durée étant globale (§9),
elle se règle dans les réglages, pas dans une feuille propre à un bloc.

**Un seul timer peut être actif à la fois.** Lancer un bloc met automatiquement en
pause celui qui tournait.

Un **bouton discret**, ancré au coin haut-droit de l'écran, ouvre les réglages : les quatre
durées, les notifications et l'heure du rappel (§4). C'est le seul élément d'interface non
essentiel de l'écran — d'où sa discrétion, mais il est visible et lisible : des réglages
qu'on ne trouve pas ne servent à rien.

Les réglages mènent à un **écran d'aide** qui décrit les gestes — le tap, l'appui long, le
double tap sur le titre — et explique ce que dit le sablier, ainsi que pourquoi il n'y a pas
de remise à zéro. Une app sans interface visible doit dire une fois comment on s'en sert ;
l'aide est logée dans les réglages pour que l'écran principal garde exactement un bouton.

### 5.3 Fin d'un timer

Le bloc passe à l'état `termine` et une notification est envoyée si l'app est en
arrière-plan (sur l'iPhone comme sur la Watch). Le bloc terminé garde visuellement la trace
de son accomplissement : rien d'autre n'est demandé à l'utilisateur.

Concrètement, la jauge étant allée au bout, le carré devient un **aplat plein** dans la
couleur d'accent et son texte passe en négatif. Le compteur, qui n'a plus de temps restant à
annoncer, laisse place à la **durée accomplie** (« 30 min »). Rien n'est ajouté — ni coche,
ni médaille : l'état terminé est la conséquence visuelle du remplissage, pas une décoration.
Un bloc achevé se distingue ainsi d'un bloc simplement en pause sans qu'on ait à le griser,
ce qui le ferait passer pour désactivé.

### 5.4 Changement de jour

Au passage à un nouveau jour, les timers repartent à zéro avec les durées configurées.

Les **objectifs de la veille sont repris automatiquement** : on retrouve le matin les quatre
titres de la veille, prêts à être gardés tels quels ou réécrits. Beaucoup d'objectifs se
répètent d'un jour à l'autre, et repartir d'une page blanche chaque matin est une friction
inutile — c'est un point de départ, pas un engagement.

Les objectifs repris sont copiés dans une nouvelle journée (la veille reste intacte en base,
même si la v1 n'expose pas d'historique). Ce comportement n'est pas configurable en v1 :
les objectifs reviennent d'un jour à l'autre, c'est tout. Les réécrire prend le même geste
que les écrire.

### 5.5 L'autorisation d'envoyer des notifications

**Elle n'est pas demandée au premier lancement.** Une app qui réclame avant d'avoir rien
montré se fait refuser, et c'est de la friction là où la §2 n'en veut aucune. On demande au
premier moment où une notification servirait vraiment : quand on **lance un timer**, ou quand
on **valide ses objectifs** du matin — le premier des deux qui arrive.

Le bloc démarre **sans attendre la réponse** : on ne met pas une fenêtre système entre le tap
et le départ du timer. La notification de fin est reposée une fois l'autorisation connue, et
le rappel matinal programmé dans la foulée.

**Un refus n'est pas un état d'erreur.** L'app fonctionne à l'identique, elle se tait. On ne
redemande jamais — iOS ne réafficherait pas la fenêtre de toute façon — et rien n'affiche de
bandeau d'avertissement : ce serait un reproche, et la §2 n'en veut pas non plus.

## 6. Comportement du décompte

Le timer **ne doit pas** reposer sur un `Timer` qui tourne en continu. Le modèle
correct :

1. Au démarrage, on stocke la date absolue de départ.
2. Le temps restant est toujours *calculé* : `duree - tempsEcouleAvant - (maintenant - dateDemarrage)`.
3. Un timer d'affichage rafraîchit l'UI chaque seconde, mais n'est jamais la source de vérité.
4. Une notification locale est programmée à l'heure de fin dès le démarrage, puis
   annulée en cas de pause.

C'est ce qui garantit un décompte juste après une mise en arrière-plan, un verrouillage
de l'écran ou une fermeture de l'app.

## 7. Direction visuelle

Sobre, calme, typographique. Le temps qui s'écoule doit être ressenti plutôt que lu :
une jauge continue, un remplissage, une colonne qui se vide — dans l'esprit de la
clepsydre — plutôt qu'un simple cercle de progression générique.

**Les quatre blocs ont tous la même taille.** Une grille régulière, calme, où rien ne pèse
plus qu'autre chose : la différence de durée se lit dans le chiffre affiché et dans la
vitesse du remplissage, pas dans l'encombrement. Un bloc de 5 minutes mérite autant
d'attention qu'un bloc de 45.

Chaque bloc affiche son temps restant en `min:sec` par-dessus le remplissage — le chiffre
pour la précision, la surface remplie pour la sensation.

Accessibilité : Dynamic Type, VoiceOver sur l'état de chaque bloc, contrastes
suffisants, mode sombre.

### 7.1 Mise en page

Une seule idée déclinée : des carrés identiques, centrés, entourés de vide. Le vide fait
partie du dessin — il donne le calme et empêche l'écran de ressembler à une liste de tâches.

**iPhone / iPad, portrait** — grille 2 × 2, centrée verticalement.

```
+---------------------+
|                     |
|                     |
|  _______   _______  |
| |       | |       | |
| | 05:00 | | 15:00 | |
| |_______| |_______| |
|                     |
|  _______   _______  |
| |       | |       | |
| | 30:00 | | 45:00 | |
| |_______| |_______| |
|                     |
|                     |
+---------------------+
```

**iPhone / iPad, paysage** — une seule rangée de quatre, dans l'ordre des durées.

```
+-----------------------------------------+
|                                         |
|  _______   _______   _______   _______  |
| |       | |       | |       | |       | |
| | 05:00 | | 15:00 | | 30:00 | | 45:00 | |
| |_______| |_______| |_______| |_______| |
|                                         |
+-----------------------------------------+
```

La bascule portrait ↔ paysage est une **réorganisation de la même grille**, pas un autre
écran : mêmes blocs, mêmes tailles relatives, transition animée. Sur iPad les carrés
grandissent avec l'écran plutôt que de se multiplier ou de laisser place à une barre
latérale — la contrainte des quatre blocs vaut sur toutes les tailles.

**Apple Watch** — un seul bloc à l'écran, occupant l'essentiel de la surface. Un balayage
horizontal (gauche/droite) passe au bloc suivant ou précédent, et un indicateur de page
rappelle où l'on se trouve dans les quatre.

```
+-------------+
|   _______   |
|  |       |  |
|  | 05:00 |  |
|  |_______|  |
|   * . . .   |
+-------------+
```

Sur la montre, le bloc en cours est celui qu'on voit à l'ouverture ; sinon, le premier bloc
non terminé. La couronne digitale suit le même défilement que le balayage.

### 7.2 L'en-tête

Au-dessus de la grille, centré horizontalement et au milieu de l'espace qui reste :
**CLEPSYDRE** en capitales interlettrées, dans la serif système, précédé d'une clepsydre
dessinée en vectoriel.

Cette clepsydre suit **l'heure civile**, pas l'avancement des blocs : à midi elle est à
moitié vide, à 20h il n'y reste presque rien. Elle ne dit pas si on a bien travaillé — elle
rappelle que le jour s'écoule de toute façon, ce qui est le sujet de l'app.

Le dessin obéit à trois règles :

- **Les volumes varient en aire, pas en hauteur.** Les bulbes s'évasent vers les extrémités,
  donc à hauteur égale les tranches n'ont pas le même volume ; faire varier la hauteur
  linéairement donnerait un écoulement qui semble s'emballer sur la fin.
- **Une pseudo-physique**, pour que ce soit du sable et pas une jauge : la surface du haut se
  creuse en entonnoir vers le col, le tas du bas est bombé là où le sable retombe, et un
  filet traverse le goulot tant qu'il reste quelque chose à faire passer.
- **L'épaisseur du trait est proportionnelle à la taille.** Un trait fixe disparaît dès qu'on
  agrandit le dessin — ce qui compte, puisqu'il sert aussi d'icône (§8.2).

Le dessin vit dans le module partagé : il n'existe qu'en un seul exemplaire.

### 7.3 Couleurs et thème

**Une couleur par bloc.** Les quatre teintes — terre cuite, ambre, sauge, prune — sont
espacées sur le cercle chromatique pour qu'on reconnaisse un bloc à sa couleur avant même
d'en lire le titre. Elles restent rabattues en saturation : quatre voix distinctes, pas
quatre néons. Le bleu, lui, est réservé à la clepsydre de l'en-tête — c'est la signature de
l'app, il ne désigne aucun bloc.

Chaque teinte a une **variante pour le mode sombre**, un peu plus claire et moins saturée :
une couleur pensée pour un fond blanc paraît sale sur fond noir.

La couleur est présente **dès le repos** : le fond d'un bloc porte déjà sa teinte très
diluée, et le remplissage la reprend en plein par-dessus. Sans cela, quatre blocs non lancés
seraient quatre rectangles gris — ce qui se remarque à peine sur un iPhone mais saute aux
yeux sur un iPad, où les carrés font près de 480 pt de côté.

**Le thème se bascule par un double tap sur le titre.** C'est délibérément discret : ce n'est
pas un réglage qu'on cherche, c'est une préférence qu'on pose une fois. Le choix est
persistant. Tant que l'utilisateur n'a rien choisi, l'app suit le réglage du système ; le
premier double tap fixe l'inverse de ce qui est affiché, et l'app cesse alors de suivre le
système.

## 8. Technique

- **Plateformes** : iOS (iPhone + iPad, portrait et paysage) + watchOS, SwiftUI
- **Architecture** : un module partagé (modèle, décompte, planification des notifications)
  consommé par les deux cibles ; l'UI seule est spécifique à chaque plateforme. Ce module est
  un **Swift Package local** (`ClepsydreCore`), compilable et testable sans passer par Xcode
- **Tests** : **Swift Testing** (`@Test`, `#expect`)
- **Persistance** : SwiftData
- **iPhone ↔ Watch** : `WatchConnectivity`, l'iPhone faisant autorité
- **Notifications** : `UNUserNotificationCenter`, notifications locales (fin de timer +
  rappel matinal récurrent)
- **Team ID** : WFMP87LTRX
- **Pas de dépendance externe** en v1

### 8.1 Génération du projet

Le projet Xcode est décrit dans un `project.yml` et généré par **XcodeGen**. Le `.xcodeproj`
n'est pas la source de vérité et n'a pas vocation à être édité à la main : on modifie le YAML
puis on régénère.

Réglages notables, au-delà de ce que produit XcodeGen par défaut :

- `developmentLanguage: fr` — indique à iOS que la langue principale de l'app est le
  français. Sans ça, les menus système fournis par UIKit (couper, copier, coller,
  sélectionner…) apparaissent en anglais même sur un appareil configuré en français.
- `GENERATE_INFOPLIST_FILE: YES` — l'`Info.plist` est entièrement généré par Xcode à partir
  des build settings ; aucun fichier `.plist` à maintenir à la main. Appliqué sur toutes les
  cibles, app comme tests.
- `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` — lie le build setting à l'asset catalog pour
  que Xcode trouve l'icône automatiquement.
- `INFOPLIST_KEY_UISupportedInterfaceOrientations_iPhone` / `_iPad` — les quatre orientations
  sont autorisées sur les deux familles d'appareils. C'est cohérent avec les mises en page
  portrait et paysage de la §7.1, et requis par Apple pour le multitâche iPad (validation
  App Store).

### 8.2 Icône

L'icône n'est pas une image dessinée à part : elle est **rendue depuis le même code** que la
clepsydre de l'en-tête (§7.2), par un outil de développement du module partagé.

```
cd ClepsydreCore
swift run IcôneClepsydre ../Clepsydre/Assets.xcassets/AppIcon.appiconset/icone-1024.png 15
```

Le dernier argument est l'heure affichée par la clepsydre — 15h par défaut, moment où les
deux tas et le filet sont visibles ensemble. L'outil ne fait pas partie de l'app : c'est un
`executableTarget` du package, jamais lié aux cibles iOS ou watchOS.

Faire l'icône ainsi a un effet secondaire utile : tout défaut du dessin saute aux yeux à
1024 px alors qu'il passait inaperçu à 26 pt.

### 8.3 Pièges rencontrés

Deux points que le code respecte et qu'il ne faut pas « moderniser » par réflexe :

- **Le délégué de notifications s'écrit avec ses handlers de complétion, pas en `async`.**
  Swift ponte les versions `async` vers les versions à complétion et appelle le handler
  depuis le thread coopératif où la tâche s'est achevée ; UIKit exige le thread principal et
  lève une assertion, ce qui arrête l'app. Écrites à la main, on maîtrise d'où le handler
  part. Les handlers d'UIKit n'étant pas marqués `Sendable`, ils transitent par une petite
  boîte `@unchecked Sendable` — seul endroit du projet qui en ait besoin.
- **Un seul modificateur `.sheet` par vue.** Deux feuilles attachées à la même vue relèvent
  du comportement non défini ; l'écran principal décrit donc sa présentation par un état
  unique à plusieurs cas.

- **Sur l'appareil, journaliser avec `NSLog`.** `print` écrit sur une sortie standard
  bufferisée qui n'est jamais relayée jusqu'à la console de `devicectl` ; seule la sortie du
  système de journalisation l'est. C'est ainsi qu'on vérifie ce qui est réellement programmé,
  en lançant l'app avec `devicectl device process launch --console`.

Et pour diagnostiquer un plantage sur l'appareil, plutôt que de raisonner par plausibilité :

```
xcrun devicectl device copy from --device <appareil> \
  --source / --destination <dossier> --domain-type systemCrashLogs
```

### 8.4 Tests

**On écrit des tests unitaires dès que c'est possible.** C'est d'ailleurs une raison de plus
d'isoler le modèle et la logique de décompte dans le module partagé (§3.1) : tout ce qui
compte vraiment devient testable sans interface.

Cibles prioritaires :

- le calcul du temps restant, y compris après une longue mise en arrière-plan
- l'enchaînement des états d'un bloc, et l'impossibilité d'en sortir une fois `termine`
- la mise en pause automatique du bloc actif quand un autre démarre
- le passage à un nouveau jour : blocs remis à zéro, objectifs repris
- la programmation et l'annulation des notifications au démarrage et à la pause

Le décompte étant calculé à partir de dates absolues et jamais d'un `Timer` (§6), l'horloge
doit être **injectable** dans la logique métier : c'est ce qui permet de simuler « trois
heures plus tard » dans un test au lieu d'attendre.

## 9. Décisions tranchées

**Un objectif non terminé en fin de journée** — rien de particulier. Le lendemain, les blocs
repartent à zéro et on refait un tour, avec les mêmes objectifs repris (§5.4). Pas de report,
pas de mention d'un échec, pas de compteur de jours manqués. La journée d'hier est finie,
c'est tout.

**Les durées sont globales** — les quatre durées vivent dans les `Reglages` et valent pour
tous les jours. On les ajuste rarement, une fois qu'on a trouvé son rythme ; les redéfinir
chaque matin ajouterait une décision quotidienne pour rien.

**Un bloc terminé ne se relance pas** — il reste `termine` jusqu'au lendemain. Prolonger une
session, c'est ce que le temps libre après le bloc permet déjà (§3) ; le timer, lui, a fait
son travail.

**Aucun ordre imposé** — les quatre blocs sont lançables dans n'importe quel ordre. La grille
n'est pas une file d'attente : on prend le bloc qui correspond au temps et à l'énergie
disponibles. Seule contrainte, inchangée : un seul timer actif à la fois (§5.2).
