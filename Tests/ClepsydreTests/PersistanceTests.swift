import ClepsydreCore
import Foundation
import SwiftData
import Testing

/// Vérifie que le modèle tient debout une fois branché sur SwiftData — ce que les tests
/// du module partagé, qui travaillent sur des objets en mémoire, ne couvrent pas.
@Suite("Persistance")
@MainActor
struct PersistanceTests {
    private func contexteEnMemoire() throws -> ModelContext {
        let conteneur = try ModelContainer(
            for: Bloc.self, Objectif.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        return ModelContext(conteneur)
    }

    @Test("Un bloc en cours retrouve son état après relecture")
    func blocPersiste() throws {
        let contexte = try contexteEnMemoire()
        let depart = Date()
        let bloc = Bloc(position: 2, duree: 1800)
        contexte.insert(bloc)
        bloc.demarrer(a: depart)
        try contexte.save()

        let relus = try contexte.fetch(FetchDescriptor<Bloc>())
        let relu = try #require(relus.first)
        #expect(relu.etat == .enCours)
        #expect(relu.position == 2)
        #expect(relu.tempsRestant(a: depart.addingTimeInterval(600)) == 1200)
    }

    @Test("Les objectifs se retrouvent par journée")
    func objectifsParJour() throws {
        let contexte = try contexteEnMemoire()
        let aujourdhui = Calendar.current.startOfDay(for: Date())
        let veille = aujourdhui.addingTimeInterval(-86_400)

        contexte.insert(Objectif(titre: "Hier", date: veille, position: 0))
        contexte.insert(Objectif(titre: "Aujourd'hui", date: aujourdhui, position: 0))
        try contexte.save()

        let descripteur = FetchDescriptor<Objectif>(
            predicate: #Predicate { $0.date == aujourdhui }
        )
        #expect(try contexte.fetch(descripteur).map(\.titre) == ["Aujourd'hui"])
    }
}
