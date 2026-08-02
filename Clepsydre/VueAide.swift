import ClepsydreCore
import SwiftUI

/// L'aide : les gestes, et le pourquoi de ce qui n'existe pas.
///
/// L'app n'a presque aucun élément d'interface : ce que ça coûte, c'est qu'il faut dire une
/// fois comment on s'en sert.
struct VueAide: View {
    @Environment(\.colorScheme) private var theme

    var body: some View {
        List {
            Section {
                Text("Chaque matin, quatre objectifs et quatre durées. On lance un bloc, on va au bout, et la journée se construit comme ça.")
                    .font(.system(.body, design: .serif))
                    .padding(.vertical, 4)
            }

            Section("Les gestes") {
                geste(
                    symbole: "hand.tap",
                    titre: "Toucher un carré",
                    texte: "Lance son minuteur, ou le met en pause. Un seul bloc peut tourner à la fois : en lancer un met l'autre en pause."
                )
                geste(
                    symbole: "hand.tap.fill",
                    titre: "Appui long sur un carré",
                    texte: "Change l'objectif du bloc, sans interrompre ce qui tourne."
                )
                geste(
                    symbole: "circle.lefthalf.filled",
                    titre: "Double tap sur le titre",
                    texte: "Bascule entre le thème clair et le thème sombre. Le choix est retenu."
                )
                geste(
                    symbole: "slider.horizontal.3",
                    titre: "Le bouton en haut",
                    texte: "Les durées des quatre blocs, les notifications et l'heure du rappel du matin."
                )
            }

            Section("Le sablier") {
                HStack(spacing: 16) {
                    VueClepsydre(sableRestant: 0.4)
                        .tint(PaletteBlocs.clepsydre)
                        .frame(width: 30, height: 40)
                    Text("Il suit l'heure qu'il est, pas ton avancement. À midi il est à moitié vide, le soir il ne reste presque rien.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section {
                Text("Un bloc lancé ne se remet pas à zéro. La durée qu'on se donne est un minimum, pas un quota : prévoir trente minutes de lecture et en faire quarante-cinq, c'est très bien. Et un bloc qu'on n'a pas fait n'est pas un échec — demain, on repart.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            } header: {
                Text("Ce qui n'existe pas, et pourquoi")
            }
        }
        .navigationTitle("Aide")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func geste(symbole: String, titre: String, texte: String) -> some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbole)
                .font(.system(size: 18))
                .foregroundStyle(.secondary)
                .frame(width: 26)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(titre).font(.headline)
                Text(texte).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}
