import ClepsydreCore
import Observation
import UserNotifications

/// Reçoit les taps sur les notifications et dit à l'app quoi ouvrir.
///
/// Un tap sur le rappel matinal doit mener directement à l'écran de saisie (SPECS §5.1) ;
/// sans délégué, iOS se contente de lancer l'app sur l'écran principal.
@MainActor
@Observable
final class RouteurDeNotifications: NSObject, UNUserNotificationCenterDelegate {
    /// Passe à `true` quand l'utilisateur touche le rappel du matin.
    var rituelDemande = false

    func installer(sur centre: UNUserNotificationCenter = .current()) {
        centre.delegate = self
    }

    /// Les handlers d'UIKit ne sont pas marqués `Sendable`, alors qu'ils sont bel et bien
    /// faits pour être rappelés depuis une autre file. On les transporte donc dans cette
    /// boîte, le temps de passer sur le thread principal.
    private struct Boite<Contenu>: @unchecked Sendable {
        let contenu: Contenu
    }

    // Ces deux méthodes sont écrites avec un handler de complétion plutôt qu'en `async`.
    //
    // Ce n'est pas un archaïsme : la version `async` est pontée vers la version à complétion
    // par Swift, qui appelle le handler depuis le thread coopératif où la tâche s'est
    // achevée. UIKit exige le thread principal et lève une assertion — l'app s'arrête.
    // En les écrivant à la main, on maîtrise d'où le handler est appelé.

    /// Une notification qui arrive alors que l'app est ouverte reste visible : la fin d'un
    /// bloc mérite d'être vue même si on a l'écran sous les yeux.
    nonisolated func userNotificationCenter(
        _ centre: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let boite = Boite(contenu: completionHandler)
        DispatchQueue.main.async {
            boite.contenu([.banner, .sound])
        }
    }

    /// Le délégué reçoit des types non `Sendable` : on en extrait tout de suite
    /// l'identifiant, seule chose dont on ait besoin, avant de passer sur le thread
    /// principal.
    nonisolated func userNotificationCenter(
        _ centre: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let identifiant = response.notification.request.identifier
        let boite = Boite(contenu: completionHandler)
        DispatchQueue.main.async {
            MainActor.assumeIsolated {
                if identifiant == PlanificateurSysteme.identifiantDuRappelMatinal {
                    self.rituelDemande = true
                }
            }
            boite.contenu()
        }
    }
}
