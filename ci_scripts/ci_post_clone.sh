#!/bin/sh
# Xcode Cloud — exécuté après le clonage, avant la compilation.
#
# Le projet committé est celui du quotidien : iOS seul, sans app Watch embarquée, pour que
# le Mac de développement puisse compiler sans le SDK watchOS. Xcode Cloud, lui, dispose de
# tous les SDK : on régénère donc le projet à partir de la variante qui embarque la montre,
# faute de quoi l'app Watch n'atteindrait jamais TestFlight.
set -e

brew install xcodegen

cd "$CI_PRIMARY_REPOSITORY_PATH"
xcodegen generate --spec project-avec-montre.yml

echo "Projet régénéré avec l'app Watch embarquée."
