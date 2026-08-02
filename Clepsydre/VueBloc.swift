import ClepsydreCore
import SwiftUI

/// Un carré qui se remplit à mesure que le temps s'écoule, avec le temps restant en clair.
///
/// Tous les blocs ont la même taille : la durée se lit au chiffre et à la vitesse du
/// remplissage, pas à l'encombrement (SPECS §7).
struct VueBloc: View {
    let bloc: Bloc
    let objectif: Objectif?
    let maintenant: Date
    /// La teinte propre au bloc : on reconnaît un bloc à sa couleur (SPECS §7).
    let couleur: Color

    @Environment(\.colorScheme) private var theme

    private var progression: Double { bloc.progression(a: maintenant) }
    private var restant: TimeInterval { bloc.tempsRestant(a: maintenant) }

    var body: some View {
        VStack(spacing: 8) {
            Text(titre)
                .font(.headline)
                .foregroundStyle(couleurDuTitre)
                .lineLimit(2)
                .multilineTextAlignment(.center)

            Text(tempsAffiche)
                .font(.system(.largeTitle, design: .rounded, weight: .medium))
                .monospacedDigit()
                .contentTransition(.numericText())
                .foregroundStyle(acheve ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
        }
        .padding(16)
        // La taille du carré est décidée par la grille (VueJournee), pas ici.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(remplissage)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        // Le bloc en cours se signale par sa bordure : sobre, lisible en plein soleil,
        // et sans introduire de profondeur là où tout le reste du dessin est plat.
        .overlay {
            RoundedRectangle(cornerRadius: 24)
                .strokeBorder(
                    bloc.etat == .enCours ? AnyShapeStyle(couleur) : AnyShapeStyle(.separator),
                    lineWidth: bloc.etat == .enCours ? 3 : 1
                )
        }
        .animation(.smooth, value: progression)
        .animation(.smooth(duration: 0.25), value: bloc.etat)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(titre)
        .accessibilityValue(descriptionAccessible)
    }

    /// Le remplissage monte depuis le bas, comme l'eau dans une clepsydre.
    private var remplissage: some View {
        GeometryReader { geometrie in
            ZStack(alignment: .bottom) {
                // Le fond porte déjà la teinte du bloc, très diluée : chaque carré s'annonce
                // dès l'ouverture, au lieu d'attendre qu'on lance son timer pour exister.
                Rectangle().fill(couleur.opacity(sombre ? 0.22 : 0.12))
                Rectangle()
                    .fill(couleur.opacity(opaciteDuRemplissage))
                    .frame(height: geometrie.size.height * progression)
            }
        }
    }

    /// Un bloc mené à son terme : la jauge est allée au bout, le carré est un aplat plein
    /// et le texte passe en négatif. Rien n'est ajouté — c'est la conséquence de la jauge,
    /// pas une décoration ni une coche (SPECS §3, §5.3).
    private var acheve: Bool { bloc.etat == .termine }

    private var sombre: Bool { theme == .dark }

    /// Les opacités sont plus fortes en mode sombre : une couleur posée sur du noir perd
    /// beaucoup plus vite sa présence que la même posée sur du blanc.
    private var opaciteDuRemplissage: Double {
        switch bloc.etat {
        case .termine: return sombre ? 1 : 0.95
        case .enPause: return sombre ? 0.5 : 0.35
        default: return sombre ? 0.8 : 0.6
        }
    }

    private var couleurDuTitre: AnyShapeStyle {
        if acheve { return AnyShapeStyle(.white) }
        return AnyShapeStyle(objectif?.estVide == false ? .primary : .tertiary)
    }

    private var titre: String {
        if let objectif, !objectif.estVide { return objectif.titre }
        return "Sans objectif"
    }

    /// Le compteur laisse place à la durée accomplie : un bloc fini n'a plus de temps
    /// restant à annoncer, il a une durée à son actif.
    private var tempsAffiche: String {
        if acheve { return "\(Int(bloc.duree) / 60) min" }
        let secondes = Int(bloc.etat == .enAttente ? bloc.duree : restant.rounded(.up))
        return String(format: "%02d:%02d", secondes / 60, secondes % 60)
    }

    private var descriptionAccessible: String {
        let minutes = Int(restant.rounded(.up)) / 60
        switch bloc.etat {
        case .enAttente: return "Bloc de \(Int(bloc.duree) / 60) minutes, pas encore lancé"
        case .enCours: return "En cours, \(minutes) minutes restantes"
        case .enPause: return "En pause, \(minutes) minutes restantes"
        case .termine: return "Terminé, \(Int(bloc.duree) / 60) minutes accomplies"
        }
    }
}
