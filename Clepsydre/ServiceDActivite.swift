import ActivityKit
import ClepsydreCore
import Foundation

/// Tient à jour la Live Activity du bloc en cours (SPECS §5.6).
///
/// Une seule activité à la fois, comme il n'y a qu'un seul timer actif à la fois (§5.2).
/// L'activité survit à la pause — c'est justement là qu'on a besoin du bouton pour relancer —
/// et disparaît quand le bloc est terminé ou remis à zéro.
@MainActor
final class ServiceDActivite {
    private var activite: Activity<AttributsDeBloc>?
    /// Le bloc que l'activité représente, y compris quand il est en pause.
    private var blocSuivi: UUID?

    /// Aligne l'activité sur l'état réel des blocs. Appelé au démarrage, à chaque bascule et
    /// à chaque battement d'affichage.
    func refleter(blocs: [Bloc], titre: (Bloc) -> String, a instant: Date) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        guard let bloc = blocAMontrer(parmi: blocs) else {
            terminer()
            return
        }

        let etat = AttributsDeBloc.ContentState.decrivant(bloc, titre: titre(bloc), a: instant)

        if blocSuivi == bloc.id, let activite {
            let paquet = Boite(
                contenu: (activite, ActivityContent(state: etat, staleDate: bloc.dateDeFinPrevue))
            )
            Self.mettreAJour(paquet)
            return
        }

        terminer()
        demarrer(pour: bloc, etat: etat)
    }

    /// Le bloc qui tourne ; à défaut, celui qu'on suivait et qui vient de passer en pause.
    private func blocAMontrer(parmi blocs: [Bloc]) -> Bloc? {
        if let enCours = Journee.blocEnCours(parmi: blocs) { return enCours }
        return blocs.first { $0.id == blocSuivi && $0.etat == .enPause }
    }

    private func demarrer(pour bloc: Bloc, etat: AttributsDeBloc.ContentState) {
        let attributs = AttributsDeBloc(
            position: bloc.position,
            identifiantDuBloc: bloc.id.uuidString
        )
        activite = try? Activity.request(
            attributes: attributs,
            content: ActivityContent(state: etat, staleDate: bloc.dateDeFinPrevue),
            pushType: nil
        )
        blocSuivi = activite == nil ? nil : bloc.id
    }

    func terminer() {
        guard let activite else { return }
        self.activite = nil
        blocSuivi = nil
        Self.clore(Boite(contenu: activite))
    }

    // MARK: - Franchissement de la frontière de concurrence

    /// `Activity` et `ActivityContent` ne sont pas marqués `Sendable`, alors que leurs
    /// méthodes sont `async` et non isolées : les appeler depuis le main actor demande de les
    /// « envoyer », ce que Swift 6 refuse. On les transporte donc dans cette boîte, comme
    /// pour les handlers d'UIKit (SPECS §8.3).
    private struct Boite<Contenu>: @unchecked Sendable {
        let contenu: Contenu
    }

    private nonisolated static func mettreAJour(
        _ paquet: Boite<(Activity<AttributsDeBloc>, ActivityContent<AttributsDeBloc.ContentState>)>
    ) {
        Task { await paquet.contenu.0.update(paquet.contenu.1) }
    }

    private nonisolated static func clore(_ paquet: Boite<Activity<AttributsDeBloc>>) {
        Task { await paquet.contenu.end(nil, dismissalPolicy: .immediate) }
    }
}
