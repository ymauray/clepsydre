import Foundation
import Testing
@testable import ClepsydreCore

private let midi = Date(timeIntervalSince1970: 1_700_000_000)

/// Enregistre les appels au lieu de parler au système.
private final class PlanificateurEspion: PlanificateurDeNotifications {
    enum Appel: Equatable {
        case programmee(identifiant: String, instant: Date)
        case annulee(identifiant: String)
        case rappelProgramme(DateComponents)
        case rappelAnnule
    }

    private(set) var appels: [Appel] = []

    func programmerFinDeBloc(identifiant: String, a instant: Date, titreObjectif: String) {
        appels.append(.programmee(identifiant: identifiant, instant: instant))
    }

    func annulerFinDeBloc(identifiant: String) {
        appels.append(.annulee(identifiant: identifiant))
    }

    func programmerRappelMatinal(a heure: DateComponents) {
        appels.append(.rappelProgramme(heure))
    }

    func annulerRappelMatinal() {
        appels.append(.rappelAnnule)
    }
}

@Suite("Notifications")
struct NotificationsTests {
    private let horloge = HorlogeFigee(midi)
    private let espion = PlanificateurEspion()
    private var blocs: [Bloc] {
        Reglages.dureesParDefaut.enumerated().map { Bloc(position: $0.offset, duree: $0.element) }
    }

    private func service(_ reglages: Reglages = Reglages()) -> ServiceDeBlocs {
        ServiceDeBlocs(horloge: horloge, notifications: espion) { reglages }
    }

    @Test("Le départ programme la notification à l'heure de fin")
    func programmationAuDepart() {
        let blocs = blocs
        service().basculer(blocs[0], parmi: blocs)

        #expect(espion.appels == [
            .programmee(identifiant: blocs[0].id.uuidString, instant: midi.addingTimeInterval(300))
        ])
    }

    @Test("La pause annule la notification")
    func annulationALaPause() {
        let blocs = blocs
        let service = service()
        service.basculer(blocs[0], parmi: blocs)
        horloge.avancer(de: 60)
        service.basculer(blocs[0], parmi: blocs)

        #expect(espion.appels.last == .annulee(identifiant: blocs[0].id.uuidString))
    }

    @Test("Changer de bloc annule l'ancienne notification et programme la nouvelle")
    func changementDeBloc() {
        let blocs = blocs
        let service = service()
        service.basculer(blocs[0], parmi: blocs)
        horloge.avancer(de: 60)
        service.basculer(blocs[1], parmi: blocs)

        #expect(espion.appels == [
            .programmee(identifiant: blocs[0].id.uuidString, instant: midi.addingTimeInterval(300)),
            .annulee(identifiant: blocs[0].id.uuidString),
            .programmee(
                identifiant: blocs[1].id.uuidString,
                instant: midi.addingTimeInterval(60 + 15 * 60)
            )
        ])
    }

    @Test("Notifications désactivées : on ne programme rien")
    func notificationsDesactivees() {
        let blocs = blocs
        service(Reglages(notificationsDeFinActivees: false)).basculer(blocs[0], parmi: blocs)

        #expect(espion.appels.isEmpty)
        #expect(blocs[0].etat == .enCours)
    }

    @Test("Le rappel matinal suit les réglages")
    func rappelMatinal() {
        service().appliquerRappelMatinal()
        #expect(espion.appels == [.rappelProgramme(DateComponents(hour: 8, minute: 0))])

        service(Reglages(rappelMatinalActive: false)).appliquerRappelMatinal()
        #expect(espion.appels.last == .rappelAnnule)
    }

    @Test("Le retour au premier plan termine les blocs échus")
    func rafraichissementAuRetour() {
        let blocs = blocs
        let service = service()
        service.basculer(blocs[0], parmi: blocs)
        horloge.avancer(de: 3600)

        #expect(service.rafraichir(blocs).count == 1)
        #expect(blocs[0].etat == .termine)
    }
}
