import ClepsydreCore
import SwiftUI

/// Le bloc plein écran de la montre : le carré occupe l'essentiel de la surface.
struct VueBlocWatch: View {
    let bloc: Bloc
    let objectif: Objectif?
    let maintenant: Date
    let basculer: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            Text(objectif?.estVide == false ? objectif!.titre : "Sans objectif")
                .font(.caption)
                .foregroundStyle(objectif?.estVide == false ? .primary : .secondary)
                .lineLimit(1)

            Button(action: basculer) {
                ZStack(alignment: .bottom) {
                    Rectangle().fill(.fill.quaternary)
                    GeometryReader { geometrie in
                        Rectangle()
                            .fill(.tint.opacity(bloc.etat == .enPause ? 0.35 : 0.6))
                            .frame(
                                height: geometrie.size.height * bloc.progression(a: maintenant),
                                alignment: .bottom
                            )
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                    Text(tempsAffiche)
                        .font(.system(.title2, design: .rounded, weight: .medium))
                        .monospacedDigit()
                        .frame(maxHeight: .infinity)
                }
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .disabled(bloc.etat == .termine)
        }
        .padding(.horizontal, 8)
        .accessibilityLabel(objectif?.titre ?? "Bloc \(bloc.position + 1)")
    }

    private var tempsAffiche: String {
        let restant = bloc.etat == .enAttente ? bloc.duree : bloc.tempsRestant(a: maintenant)
        let secondes = Int(restant.rounded(.up))
        return String(format: "%d:%02d", secondes / 60, secondes % 60)
    }
}
