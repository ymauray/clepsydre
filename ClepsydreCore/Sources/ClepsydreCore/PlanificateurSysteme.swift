import Foundation
import UserNotifications

/// L'implémentation réelle de `PlanificateurDeNotifications`, commune à l'iPhone et à la Watch.
/// `@unchecked Sendable` : le type est sans état propre, il ne fait que relayer vers
/// `UNUserNotificationCenter`, lui-même sûr en concurrence.
public final class PlanificateurSysteme: PlanificateurDeNotifications, @unchecked Sendable {
    public static let identifiantDuRappelMatinal = "rappel-matinal"

    private let centre: UNUserNotificationCenter

    public init(centre: UNUserNotificationCenter = .current()) {
        self.centre = centre
    }

    public func demanderAutorisation() async -> Bool {
        (try? await centre.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    public func programmerFinDeBloc(identifiant: String, a instant: Date, titreObjectif: String) {
        let contenu = UNMutableNotificationContent()
        contenu.title = titreObjectif.isEmpty
            ? String(localized: "Le bloc est terminé.")
            : titreObjectif
        contenu.body = String(localized: "Le temps que tu t'étais donné est écoulé.")
        contenu.sound = .default

        let delai = max(1, instant.timeIntervalSinceNow)
        let declencheur = UNTimeIntervalNotificationTrigger(timeInterval: delai, repeats: false)
        centre.add(
            UNNotificationRequest(identifier: identifiant, content: contenu, trigger: declencheur)
        )
    }

    public func annulerFinDeBloc(identifiant: String) {
        centre.removePendingNotificationRequests(withIdentifiers: [identifiant])
        centre.removeDeliveredNotifications(withIdentifiers: [identifiant])
    }

    /// Le rappel du matin : une invitation, jamais un reproche (SPECS §5.1). Il se répète
    /// chaque jour mais jamais dans la même journée.
    public func programmerRappelMatinal(a heure: DateComponents) {
        annulerRappelMatinal()

        let contenu = UNMutableNotificationContent()
        contenu.title = String(localized: "Quatre choses aujourd'hui")
        contenu.body = String(localized: "Prends une minute pour choisir tes quatre objectifs du jour.")
        contenu.sound = .default

        let declencheur = UNCalendarNotificationTrigger(dateMatching: heure, repeats: true)
        centre.add(
            UNNotificationRequest(
                identifier: Self.identifiantDuRappelMatinal,
                content: contenu,
                trigger: declencheur
            )
        )
    }

    public func annulerRappelMatinal() {
        centre.removePendingNotificationRequests(
            withIdentifiers: [Self.identifiantDuRappelMatinal]
        )
    }
}
