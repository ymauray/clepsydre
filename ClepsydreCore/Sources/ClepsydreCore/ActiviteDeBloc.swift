#if os(iOS)
import ActivityKit
import Foundation

/// Ce qu'une Live Activity montre d'un bloc en cours, sur l'écran verrouillé et dans la
/// Dynamic Island (SPECS §5.6).
///
/// Le contenu est volontairement décrit par des **dates absolues** quand le bloc tourne :
/// `ProgressView(timerInterval:)` et `Text(timerInterval:)` s'animent alors tout seuls, sans
/// qu'on ait à pousser une mise à jour chaque seconde. C'est le même principe qu'au §6 —
/// l'écoulement se calcule, il ne se rafraîchit pas.
public struct AttributsDeBloc: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var titre: String
        /// `nil` quand le bloc est en pause : il n'y a plus d'intervalle à animer.
        public var debut: Date?
        public var fin: Date?
        /// Utilisés à l'arrêt, où l'affichage est figé.
        public var progression: Double
        public var restant: TimeInterval
        public var enPause: Bool

        public init(
            titre: String,
            debut: Date?,
            fin: Date?,
            progression: Double,
            restant: TimeInterval,
            enPause: Bool
        ) {
            self.titre = titre
            self.debut = debut
            self.fin = fin
            self.progression = progression
            self.restant = restant
            self.enPause = enPause
        }
    }

    /// Sert à retrouver la couleur du bloc dans la palette.
    public var position: Int
    public var identifiantDuBloc: String

    public init(position: Int, identifiantDuBloc: String) {
        self.position = position
        self.identifiantDuBloc = identifiantDuBloc
    }
}

public extension AttributsDeBloc.ContentState {
    /// Décrit un bloc tel qu'il est à un instant donné.
    static func decrivant(_ bloc: Bloc, titre: String, a instant: Date) -> Self {
        if bloc.etat == .enCours, let depart = bloc.dateDemarrage {
            return Self(
                titre: titre,
                debut: depart.addingTimeInterval(-bloc.tempsEcoule),
                fin: bloc.dateDeFinPrevue,
                progression: bloc.progression(a: instant),
                restant: bloc.tempsRestant(a: instant),
                enPause: false
            )
        }
        return Self(
            titre: titre,
            debut: nil,
            fin: nil,
            progression: bloc.progression(a: instant),
            restant: bloc.tempsRestant(a: instant),
            enPause: true
        )
    }
}
#endif
