import ClepsydreCore
import SwiftData
import SwiftUI

@main
struct ClepsydreApp: App {
    /// Volontairement `let` et non `@State` : on y touche dès `init()`, or un `@State` n'est
    /// pas encore installé à ce moment-là et y accéder relève du comportement non défini.
    /// L'observation fonctionne quand même, `RouteurDeNotifications` étant `@Observable`.
    private let routeur = RouteurDeNotifications()

    init() {
        routeur.installer()
    }

    var body: some Scene {
        WindowGroup {
            VueJournee(routeur: routeur)
        }
        .modelContainer(for: [Bloc.self, Objectif.self])
    }
}
