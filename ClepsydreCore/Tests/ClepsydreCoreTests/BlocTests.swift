import Foundation
import Testing
@testable import ClepsydreCore

private let midi = Date(timeIntervalSince1970: 1_700_000_000)

private func bloc(duree: TimeInterval = 30 * 60, position: Int = 0) -> Bloc {
    Bloc(position: position, duree: duree)
}

@Suite("Décompte")
struct DecompteTests {
    @Test("Un bloc au repos ne consomme pas de temps")
    func auRepos() {
        let b = bloc()
        #expect(b.tempsRestant(a: midi) == 30 * 60)
        #expect(b.progression(a: midi) == 0)
    }

    @Test("Le temps restant se calcule à partir de la date de départ")
    func decompteEnCours() {
        let b = bloc()
        b.demarrer(a: midi)
        #expect(b.tempsRestant(a: midi.addingTimeInterval(600)) == 20 * 60)
        #expect(b.progression(a: midi.addingTimeInterval(900)) == 0.5)
    }

    @Test("Le décompte reste juste après une longue mise en arrière-plan")
    func apresArrierePlan() {
        let b = bloc(duree: 45 * 60)
        b.demarrer(a: midi)
        // L'app est restée fermée trois heures : le temps restant est plafonné à zéro,
        // il ne devient jamais négatif.
        let troisHeuresPlusTard = midi.addingTimeInterval(3 * 3600)
        #expect(b.tempsRestant(a: troisHeuresPlusTard) == 0)
        #expect(b.progression(a: troisHeuresPlusTard) == 1)
    }

    @Test("La pause fige la progression")
    func pause() {
        let b = bloc()
        b.demarrer(a: midi)
        b.mettreEnPause(a: midi.addingTimeInterval(600))

        #expect(b.etat == .enPause)
        #expect(b.dateDemarrage == nil)
        // Une heure passe pendant la pause, sans effet sur le décompte.
        #expect(b.tempsRestant(a: midi.addingTimeInterval(3600)) == 20 * 60)
    }

    @Test("La reprise cumule les segments")
    func reprise() {
        let b = bloc()
        b.demarrer(a: midi)
        b.mettreEnPause(a: midi.addingTimeInterval(600))
        b.demarrer(a: midi.addingTimeInterval(3600))

        #expect(b.tempsRestant(a: midi.addingTimeInterval(3900)) == 15 * 60)
    }

    @Test("La date de fin prévue sert d'heure de notification")
    func dateDeFin() {
        let b = bloc()
        #expect(b.dateDeFinPrevue == nil)
        b.demarrer(a: midi)
        #expect(b.dateDeFinPrevue == midi.addingTimeInterval(30 * 60))
    }

    @Test("Une durée nulle ne provoque pas de division par zéro")
    func dureeNulle() {
        let b = bloc(duree: 0)
        #expect(b.progression(a: midi) == 1)
    }
}

@Suite("États d'un bloc")
struct EtatTests {
    @Test("Un bloc échu passe à terminé")
    func termineSiEchu() {
        let b = bloc(duree: 300)
        b.demarrer(a: midi)

        #expect(b.terminerSiEchu(a: midi.addingTimeInterval(299)) == false)
        #expect(b.terminerSiEchu(a: midi.addingTimeInterval(300)))
        #expect(b.etat == .termine)
        #expect(b.tempsEcoule == 300)
    }

    @Test("Une pause au-delà de la durée termine le bloc")
    func pauseAuDela() {
        let b = bloc(duree: 300)
        b.demarrer(a: midi)
        b.mettreEnPause(a: midi.addingTimeInterval(400))
        #expect(b.etat == .termine)
    }

    @Test("Un bloc terminé ne se relance pas")
    func pasDeRelance() {
        let b = bloc(duree: 300)
        b.demarrer(a: midi)
        b.terminerSiEchu(a: midi.addingTimeInterval(300))

        #expect(b.peutDemarrer == false)
        #expect(b.demarrer(a: midi.addingTimeInterval(600)) == false)
        #expect(b.etat == .termine)
    }

    @Test("Mettre en pause un bloc qui ne tourne pas ne change rien")
    func pauseSansEffet() {
        let b = bloc()
        #expect(b.mettreEnPause(a: midi) == false)
        #expect(b.etat == .enAttente)
    }

    @Test("Le nouveau jour remet le bloc à zéro avec la durée globale")
    func nouveauJour() {
        let b = bloc(duree: 300)
        b.demarrer(a: midi)
        b.terminerSiEchu(a: midi.addingTimeInterval(300))

        b.preparerNouveauJour(duree: 15 * 60)
        #expect(b.etat == .enAttente)
        #expect(b.tempsEcoule == 0)
        #expect(b.dateDemarrage == nil)
        #expect(b.duree == 15 * 60)
    }
}
