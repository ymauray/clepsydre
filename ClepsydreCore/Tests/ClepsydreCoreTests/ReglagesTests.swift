import Foundation
import Testing
@testable import ClepsydreCore

@Suite("Réglages")
struct ReglagesTests {
    @Test("Les durées par défaut sont 5, 15, 30 et 45 minutes")
    func valeursParDefaut() {
        #expect(Reglages().durees == [300, 900, 1800, 2700])
        #expect(Reglages().heureDuRappel.hour == 8)
        #expect(Reglages().rappelMatinalActive)
    }

    @Test("Une position hors des durées enregistrées retombe sur le défaut")
    func positionHorsListe() {
        let reglages = Reglages(durees: [600])
        #expect(reglages.duree(pour: 0) == 600)
        #expect(reglages.duree(pour: 3) == 2700)
    }

    @Test("Les réglages survivent au redémarrage de l'app")
    func persistance() throws {
        let defaults = try #require(UserDefaults(suiteName: "test-\(UUID().uuidString)"))
        defer { defaults.removeSuite(named: defaults.description) }

        let store = ReglagesStore(defaults: defaults)
        store.reglages.durees[0] = 42 * 60
        store.reglages.rappelMatinalActive = false
        store.reglages.themeSombre = true

        let relu = ReglagesStore(defaults: defaults)
        #expect(relu.reglages.durees[0] == 42 * 60)
        #expect(relu.reglages.rappelMatinalActive == false)
        #expect(relu.reglages.themeSombre == true)
    }

    @Test("Tant que l'utilisateur n'a rien choisi, le thème suit le système")
    func themeNonChoisi() {
        #expect(Reglages().themeSombre == nil)
    }

    @Test("Chaque bloc a sa couleur, et les quatre sont distinctes")
    func palette() {
        for sombre in [false, true] {
            let couleurs = (0..<Clepsydre.nombreDeBlocs).map {
                PaletteBlocs.couleur(pour: $0, sombre: sombre)
            }
            #expect(Set(couleurs.map(String.init(describing:))).count == 4)
        }
        // Une position hors bornes ne fait pas planter l'affichage.
        #expect(PaletteBlocs.couleur(pour: 7, sombre: false) == PaletteBlocs.couleur(pour: 3, sombre: false))
    }
}
