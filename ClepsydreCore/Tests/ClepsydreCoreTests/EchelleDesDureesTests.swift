import Foundation
import Testing
@testable import ClepsydreCore

@Suite("Échelle des durées")
struct EchelleDesDureesTests {
    @Test("En montant : 1, 5, 10, 15…")
    func enMontant() {
        var minutes = EchelleDesDurees.minimum
        var suite: [Int] = [minutes]
        for _ in 0..<5 {
            minutes = EchelleDesDurees.suivante(apres: minutes)
            suite.append(minutes)
        }
        #expect(suite == [1, 5, 10, 15, 20, 25])
    }

    @Test("En descendant : 15, 10, 5, puis 1")
    func enDescendant() {
        var minutes = 15
        var suite: [Int] = [minutes]
        for _ in 0..<3 {
            minutes = EchelleDesDurees.precedente(avant: minutes)
            suite.append(minutes)
        }
        #expect(suite == [15, 10, 5, 1])
    }

    @Test("On ne descend jamais à zéro")
    func plancher() {
        #expect(EchelleDesDurees.precedente(avant: 1) == 1)
        #expect(EchelleDesDurees.precedente(avant: 5) == 1)
    }

    @Test("On ne dépasse pas trois heures")
    func plafond() {
        #expect(EchelleDesDurees.suivante(apres: 175) == 180)
        #expect(EchelleDesDurees.suivante(apres: 180) == 180)
    }

    @Test("Une durée hors échelle rejoint le cran le plus proche")
    func valeurIntermediaire() {
        // Un réglage venu d'ailleurs — une ancienne version, par exemple — doit se rattraper.
        #expect(EchelleDesDurees.suivante(apres: 7) == 10)
        #expect(EchelleDesDurees.precedente(avant: 7) == 5)
        #expect(EchelleDesDurees.suivante(apres: 2) == 5)
        #expect(EchelleDesDurees.precedente(avant: 3) == 1)
    }
}
