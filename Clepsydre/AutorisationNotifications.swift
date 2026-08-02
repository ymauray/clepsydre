import ClepsydreCore
import Observation
import UserNotifications

/// Quand demander l'autorisation d'envoyer des notifications, et que faire d'un refus.
///
/// **Pas au premier lancement.** Une app qui réclame avant d'avoir rien montré se fait
/// refuser, et c'est de la friction là où la §2 n'en veut aucune. On demande au premier
/// moment où une notification servirait vraiment : quand on lance un timer, ou quand on
/// valide ses objectifs du matin.
@MainActor
@Observable
final class AutorisationNotifications {
    private(set) var statut: UNAuthorizationStatus = .notDetermined

    private let planificateur: PlanificateurSysteme
    /// On ne demande qu'une fois par session, même si l'utilisateur enchaîne les taps.
    private var demandeEnCours = false

    init(planificateur: PlanificateurSysteme) {
        self.planificateur = planificateur
    }

    var accordee: Bool { statut == .authorized || statut == .provisional }
    /// Un refus n'est pas un état d'erreur : l'app fonctionne, elle se tait, c'est tout.
    var refusee: Bool { statut == .denied }

    func actualiser() async {
        statut = await planificateur.statutDAutorisation()
    }

    /// Demande l'autorisation si elle n'a jamais été demandée. Renvoie `true` si, au sortir,
    /// on a le droit d'envoyer des notifications.
    ///
    /// Ne redemande jamais après un refus : iOS ne réafficherait pas la fenêtre de toute
    /// façon, et insister n'apporterait rien.
    @discardableResult
    func demanderSiNecessaire() async -> Bool {
        guard !demandeEnCours else { return accordee }
        demandeEnCours = true
        defer { demandeEnCours = false }

        await actualiser()
        guard statut == .notDetermined else { return accordee }

        _ = await planificateur.demanderAutorisation()
        await actualiser()
        return accordee
    }
}
