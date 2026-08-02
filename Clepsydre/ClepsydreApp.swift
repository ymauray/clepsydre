import ClepsydreCore
import SwiftData
import SwiftUI

@main
struct ClepsydreApp: App {
    var body: some Scene {
        WindowGroup {
            VueJournee()
        }
        .modelContainer(for: [Bloc.self, Objectif.self])
    }
}
