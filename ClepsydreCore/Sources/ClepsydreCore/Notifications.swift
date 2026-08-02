import Foundation

/// Programmation des notifications locales, vue depuis la logique métier.
///
/// L'implémentation réelle s'appuie sur `UNUserNotificationCenter` côté app ; le protocole
/// permet de vérifier en test *quand* on programme et *quand* on annule, sans toucher au
/// système.
public protocol PlanificateurDeNotifications: AnyObject {
    func programmerFinDeBloc(identifiant: String, a instant: Date, titreObjectif: String)
    func annulerFinDeBloc(identifiant: String)
    func programmerRappelMatinal(a heure: DateComponents)
    func annulerRappelMatinal()
}

/// Coordonne le décompte et les notifications : programmer à chaque départ, annuler à
/// chaque pause (SPECS §6).
public struct ServiceDeBlocs {
    private let horloge: Horloge
    private let notifications: PlanificateurDeNotifications
    private let reglages: () -> Reglages

    public init(
        horloge: Horloge,
        notifications: PlanificateurDeNotifications,
        reglages: @escaping () -> Reglages
    ) {
        self.horloge = horloge
        self.notifications = notifications
        self.reglages = reglages
    }

    /// Un tap sur un bloc, notifications comprises.
    public func basculer(_ bloc: Bloc, parmi blocs: [Bloc], titreObjectif: String = "") {
        let instant = horloge.maintenant
        let enCoursAvant = Journee.blocEnCours(parmi: blocs)

        guard Journee.basculer(bloc, parmi: blocs, a: instant) else { return }

        if let enCoursAvant, enCoursAvant.etat != .enCours {
            notifications.annulerFinDeBloc(identifiant: enCoursAvant.id.uuidString)
        }
        if bloc.etat == .enCours, let fin = bloc.dateDeFinPrevue,
           reglages().notificationsDeFinActivees {
            notifications.programmerFinDeBloc(
                identifiant: bloc.id.uuidString,
                a: fin,
                titreObjectif: titreObjectif
            )
        }
    }

    /// À appeler au retour au premier plan : rattrape les blocs échus et nettoie leurs
    /// notifications déjà délivrées.
    @discardableResult
    public func rafraichir(_ blocs: [Bloc]) -> [Bloc] {
        let echus = Journee.rafraichir(blocs, a: horloge.maintenant)
        for bloc in echus {
            notifications.annulerFinDeBloc(identifiant: bloc.id.uuidString)
        }
        return echus
    }

    /// Aligne le rappel matinal sur les réglages courants.
    public func appliquerRappelMatinal() {
        let reglages = reglages()
        if reglages.rappelMatinalActive {
            notifications.programmerRappelMatinal(a: reglages.heureDuRappel)
        } else {
            notifications.annulerRappelMatinal()
        }
    }
}
