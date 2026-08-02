import Foundation
import SwiftData

/// Un bloc de temps de la journée.
///
/// Le décompte ne repose jamais sur un `Timer` : on stocke la date absolue de départ
/// et le temps restant est toujours *calculé* (SPECS §6).
@Model
public final class Bloc {
    public var id: UUID
    /// 0…3, l'emplacement dans la grille.
    public var position: Int
    /// Durée visée, reprise des réglages globaux.
    public var duree: TimeInterval
    /// Progression accumulée lors des passages précédents, hors segment en cours.
    public var tempsEcoule: TimeInterval
    public var etat: EtatBloc
    /// Horodatage du dernier départ, `nil` si le bloc ne tourne pas.
    public var dateDemarrage: Date?

    public init(
        id: UUID = UUID(),
        position: Int,
        duree: TimeInterval,
        tempsEcoule: TimeInterval = 0,
        etat: EtatBloc = .enAttente,
        dateDemarrage: Date? = nil
    ) {
        self.id = id
        self.position = position
        self.duree = duree
        self.tempsEcoule = tempsEcoule
        self.etat = etat
        self.dateDemarrage = dateDemarrage
    }
}

// MARK: - Décompte

public extension Bloc {
    /// Temps écoulé à un instant donné, segment en cours compris.
    func tempsEcoule(a instant: Date) -> TimeInterval {
        guard etat == .enCours, let depart = dateDemarrage else { return tempsEcoule }
        let segment = max(0, instant.timeIntervalSince(depart))
        return min(duree, tempsEcoule + segment)
    }

    /// Temps restant à un instant donné, jamais négatif.
    func tempsRestant(a instant: Date) -> TimeInterval {
        max(0, duree - tempsEcoule(a: instant))
    }

    /// Part de la durée déjà consommée, entre 0 et 1 — c'est ce que dessine le remplissage.
    func progression(a instant: Date) -> Double {
        guard duree > 0 else { return 1 }
        return min(1, max(0, tempsEcoule(a: instant) / duree))
    }

    /// Date de fin prévue si le bloc tourne : c'est l'heure de la notification locale.
    var dateDeFinPrevue: Date? {
        guard etat == .enCours, let depart = dateDemarrage else { return nil }
        return depart.addingTimeInterval(duree - tempsEcoule)
    }
}

// MARK: - Transitions

public extension Bloc {
    /// Un bloc terminé le reste jusqu'au lendemain (SPECS §9).
    var peutDemarrer: Bool { etat != .termine }

    @discardableResult
    func demarrer(a instant: Date) -> Bool {
        guard peutDemarrer, etat != .enCours else { return false }
        etat = .enCours
        dateDemarrage = instant
        return true
    }

    @discardableResult
    func mettreEnPause(a instant: Date) -> Bool {
        guard etat == .enCours else { return false }
        tempsEcoule = tempsEcoule(a: instant)
        dateDemarrage = nil
        etat = tempsEcoule >= duree ? .termine : .enPause
        return true
    }

    /// Fait passer le bloc à `termine` si sa durée est atteinte.
    ///
    /// Appelé au rafraîchissement de l'affichage et au retour au premier plan : c'est ce qui
    /// rattrape un bloc arrivé à échéance pendant que l'app était fermée.
    @discardableResult
    func terminerSiEchu(a instant: Date) -> Bool {
        guard etat == .enCours, tempsEcoule(a: instant) >= duree else { return false }
        tempsEcoule = duree
        dateDemarrage = nil
        etat = .termine
        return true
    }

    #if DEBUG
    /// Trappe de développement : remet le bloc à zéro, à l'arrêt.
    ///
    /// **Ne fait pas partie de l'app.** La v1 n'offre aucune réinitialisation à l'utilisateur
    /// (SPECS §3) ; ceci existe pour ne pas attendre 45 minutes en testant. Compilé
    /// uniquement en Debug, à retirer avant la mise en production.
    func reinitialiserPourDeveloppement(duree nouvelleDuree: TimeInterval) {
        preparerNouveauJour(duree: nouvelleDuree)
    }
    #endif

    /// Remet le bloc à zéro pour un nouveau jour. Il n'existe pas de réinitialisation
    /// à la demande (SPECS §3).
    func preparerNouveauJour(duree nouvelleDuree: TimeInterval) {
        duree = nouvelleDuree
        tempsEcoule = 0
        dateDemarrage = nil
        etat = .enAttente
    }
}
