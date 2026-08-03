import ActivityKit
import ClepsydreCore
import SwiftUI
import WidgetKit

@main
struct ClepsydreActivites: WidgetBundle {
    var body: some Widget {
        ActiviteDeBloc()
    }
}

/// Le bloc en cours sur l'écran verrouillé et dans la Dynamic Island (SPECS §5.6).
struct ActiviteDeBloc: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AttributsDeBloc.self) { contexte in
            VueEcranVerrouille(
                etat: contexte.state,
                couleur: couleur(pour: contexte.attributes),
                identifiant: contexte.attributes.identifiantDuBloc
            )
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .activityBackgroundTint(nil)
        } dynamicIsland: { contexte in
            let couleur = couleur(pour: contexte.attributes)

            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    VStack(alignment: .leading, spacing: 4) {
                        Entete()
                        Text(contexte.state.titre.isEmpty ? "Sans objectif" : contexte.state.titre)
                            .font(.headline)
                            .lineLimit(1)
                    }
                    .padding(.leading, 4)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    BoutonBasculer(
                        identifiant: contexte.attributes.identifiantDuBloc,
                        enPause: contexte.state.enPause,
                        couleur: couleur
                    )
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Jauge(etat: contexte.state, couleur: couleur)
                }
            } compactLeading: {
                Image(systemName: contexte.state.enPause ? "pause.fill" : "hourglass")
                    .foregroundStyle(couleur)
            } compactTrailing: {
                Compteur(etat: contexte.state)
                    .frame(maxWidth: 52)
                    .foregroundStyle(couleur)
            } minimal: {
                Image(systemName: contexte.state.enPause ? "pause.fill" : "hourglass")
                    .foregroundStyle(couleur)
            }
        }
    }

    private func couleur(pour attributs: AttributsDeBloc) -> Color {
        // L'écran verrouillé est sombre dans les deux thèmes : on prend toujours la variante
        // sombre de la palette.
        PaletteBlocs.couleur(pour: attributs.position, sombre: true)
    }
}

/// Le rappel de l'app, dans la même typographie que son en-tête : sur un écran verrouillé
/// couvert de notifications, il faut pouvoir dire d'où vient celle-ci.
private struct Entete: View {
    var body: some View {
        HStack(spacing: 7) {
            VueClepsydre(
                sableRestant: 1 - Journee.avancementDeLaJournee(a: Date()),
                epaisseur: 1
            )
            .tint(PaletteBlocs.clepsydre)
            .frame(width: 11, height: 14)

            Text("Clepsydre")
                .font(.system(.caption2, design: .serif))
                .textCase(.uppercase)
                .tracking(3)
                .foregroundStyle(.secondary)
        }
    }
}

private struct VueEcranVerrouille: View {
    let etat: AttributsDeBloc.ContentState
    let couleur: Color
    let identifiant: String

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Entete()

                HStack(alignment: .firstTextBaseline) {
                    Text(etat.titre.isEmpty ? "Sans objectif" : etat.titre)
                        .font(.headline)
                        .lineLimit(1)
                    Spacer(minLength: 12)
                    Compteur(etat: etat)
                        .font(.system(.title3, design: .rounded, weight: .medium))
                        .foregroundStyle(couleur)
                }

                Jauge(etat: etat, couleur: couleur)
            }

            BoutonBasculer(identifiant: identifiant, enPause: etat.enPause, couleur: couleur)
        }
    }
}

/// La barre d'avancement. Tant que le bloc tourne, elle s'anime seule à partir de
/// l'intervalle de dates ; en pause, elle est figée sur une valeur.
private struct Jauge: View {
    let etat: AttributsDeBloc.ContentState
    let couleur: Color

    var body: some View {
        Group {
            if let debut = etat.debut, let fin = etat.fin, !etat.enPause {
                ProgressView(timerInterval: debut...fin, countsDown: false) {
                    EmptyView()
                } currentValueLabel: {
                    EmptyView()
                }
            } else {
                ProgressView(value: etat.progression)
            }
        }
        .progressViewStyle(.linear)
        .tint(couleur)
    }
}

/// Le temps restant, animé de la même façon.
private struct Compteur: View {
    let etat: AttributsDeBloc.ContentState

    var body: some View {
        if let debut = etat.debut, let fin = etat.fin, !etat.enPause {
            Text(timerInterval: debut...fin, countsDown: true)
                .monospacedDigit()
                .multilineTextAlignment(.trailing)
        } else {
            Text(minutesEtSecondes)
                .monospacedDigit()
        }
    }

    private var minutesEtSecondes: String {
        let secondes = Int(etat.restant.rounded(.up))
        return String(format: "%d:%02d", secondes / 60, secondes % 60)
    }
}

private struct BoutonBasculer: View {
    let identifiant: String
    let enPause: Bool
    let couleur: Color

    var body: some View {
        Button(intent: BasculerLeBloc(identifiant: identifiant)) {
            Image(systemName: enPause ? "play.fill" : "pause.fill")
                .font(.system(size: 20))
                .foregroundStyle(couleur)
                .frame(width: 46, height: 46)
                .background(couleur.opacity(0.22), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(enPause ? "Reprendre" : "Mettre en pause")
    }
}
