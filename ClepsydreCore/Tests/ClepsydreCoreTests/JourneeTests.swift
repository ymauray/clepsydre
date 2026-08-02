import Foundation
import Testing
@testable import ClepsydreCore

private let midi = Date(timeIntervalSince1970: 1_700_000_000)

private func quatreBlocs() -> [Bloc] {
    Reglages.dureesParDefaut.enumerated().map { Bloc(position: $0.offset, duree: $0.element) }
}

@Suite("Journée")
struct JourneeTests {
    @Test("Lancer un bloc met en pause celui qui tournait")
    func unSeulTimerActif() {
        let blocs = quatreBlocs()
        Journee.demarrer(blocs[0], parmi: blocs, a: midi)
        Journee.demarrer(blocs[2], parmi: blocs, a: midi.addingTimeInterval(120))

        #expect(blocs[0].etat == .enPause)
        #expect(blocs[0].tempsEcoule == 120)
        #expect(blocs[2].etat == .enCours)
        #expect(Journee.blocEnCours(parmi: blocs)?.position == 2)
    }

    @Test("Les blocs se lancent dans n'importe quel ordre")
    func ordreLibre() {
        let blocs = quatreBlocs()
        #expect(Journee.demarrer(blocs[3], parmi: blocs, a: midi))
        #expect(blocs[3].etat == .enCours)
    }

    @Test("Un tap sur le bloc en cours le met en pause")
    func bascule() {
        let blocs = quatreBlocs()
        Journee.basculer(blocs[1], parmi: blocs, a: midi)
        #expect(blocs[1].etat == .enCours)

        Journee.basculer(blocs[1], parmi: blocs, a: midi.addingTimeInterval(60))
        #expect(blocs[1].etat == .enPause)
        #expect(Journee.blocEnCours(parmi: blocs) == nil)
    }

    @Test("Le rafraîchissement rattrape un bloc échu hors de l'app")
    func rafraichissement() {
        let blocs = quatreBlocs()
        Journee.demarrer(blocs[0], parmi: blocs, a: midi)

        let echus = Journee.rafraichir(blocs, a: midi.addingTimeInterval(10 * 60))
        #expect(echus.count == 1)
        #expect(echus.first?.position == 0)
        #expect(blocs[0].etat == .termine)
        // Rien de neuf au second passage.
        #expect(Journee.rafraichir(blocs, a: midi.addingTimeInterval(20 * 60)).isEmpty)
    }

    @Test("L'avancement de la journée suit l'heure qu'il est")
    func avancementDeLaJournee() throws {
        var calendrier = Calendar(identifier: .gregorian)
        calendrier.timeZone = try #require(TimeZone(identifier: "Europe/Paris"))
        let minuit = try #require(
            calendrier.date(from: DateComponents(year: 2026, month: 8, day: 2, hour: 0))
        )

        #expect(Journee.avancementDeLaJournee(a: minuit, calendrier: calendrier) == 0)

        let midiPile = minuit.addingTimeInterval(12 * 3600)
        #expect(Journee.avancementDeLaJournee(a: midiPile, calendrier: calendrier) == 0.5)

        // 20h26 : la clepsydre est presque vide.
        let soir = minuit.addingTimeInterval(20 * 3600 + 26 * 60)
        let part = Journee.avancementDeLaJournee(a: soir, calendrier: calendrier)
        #expect(abs(part - (20 + 26.0 / 60) / 24) < 0.0001)
        #expect(part > 0.85)
    }

    @Test("La Watch ouvre sur le bloc en cours, sinon le premier non terminé")
    func blocAOuvrir() {
        let blocs = quatreBlocs()
        #expect(Journee.blocAOuvrir(parmi: blocs)?.position == 0)

        Journee.demarrer(blocs[0], parmi: blocs, a: midi)
        Journee.rafraichir(blocs, a: midi.addingTimeInterval(5 * 60))
        #expect(Journee.blocAOuvrir(parmi: blocs)?.position == 1)

        Journee.demarrer(blocs[2], parmi: blocs, a: midi.addingTimeInterval(6 * 60))
        #expect(Journee.blocAOuvrir(parmi: blocs)?.position == 2)
    }
}

@Suite("Changement de jour")
struct NouveauJourTests {
    private let veille = Calendar.current.startOfDay(for: midi)
    private var lendemain: Date { veille.addingTimeInterval(86_400) }

    @Test("Les blocs repartent à zéro avec les durées globales")
    func blocsRemisAZero() {
        let blocs = quatreBlocs()
        Journee.demarrer(blocs[0], parmi: blocs, a: midi)
        Journee.rafraichir(blocs, a: midi.addingTimeInterval(600))

        _ = Journee.commencer(lendemain, blocs: blocs, objectifsDeLaVeille: [], reglages: Reglages())

        #expect(blocs.allSatisfy { $0.etat == .enAttente })
        #expect(blocs.allSatisfy { $0.tempsEcoule == 0 })
        #expect(blocs.map(\.duree) == Reglages.dureesParDefaut)
    }

    @Test("Les objectifs de la veille sont repris")
    func objectifsRepris() {
        let hier = [
            Objectif(titre: "Lire", date: veille, position: 0),
            Objectif(titre: "Sport", date: veille, position: 2)
        ]

        let aujourdhui = Journee.commencer(
            lendemain, blocs: quatreBlocs(), objectifsDeLaVeille: hier, reglages: Reglages()
        )

        #expect(aujourdhui.count == 4)
        #expect(aujourdhui.map(\.titre) == ["Lire", "", "Sport", ""])
        #expect(aujourdhui.allSatisfy { $0.date == lendemain })
        // La veille reste intacte : les objectifs sont copiés, pas déplacés.
        #expect(hier[0].date == veille)
        #expect(hier[0].id != aujourdhui[0].id)
    }

    @Test("Les durées personnalisées s'appliquent au nouveau jour")
    func dureesPersonnalisees() {
        let blocs = quatreBlocs()
        let reglages = Reglages(durees: [600, 1200, 1800, 2400])
        _ = Journee.commencer(lendemain, blocs: blocs, objectifsDeLaVeille: [], reglages: reglages)

        #expect(blocs.map(\.duree) == [600, 1200, 1800, 2400])
    }
}
