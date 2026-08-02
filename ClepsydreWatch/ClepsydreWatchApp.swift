import ClepsydreCore
import SwiftData
import SwiftUI

@main
struct ClepsydreWatchApp: App {
    var body: some Scene {
        WindowGroup {
            VueWatch()
        }
        .modelContainer(for: [Bloc.self, Objectif.self])
    }
}

/// Un seul bloc à l'écran ; le balayage horizontal passe au suivant (SPECS §7.1).
struct VueWatch: View {
    @Environment(\.scenePhase) private var phase
    @Query(sort: \Bloc.position) private var blocs: [Bloc]
    @Query(sort: \Objectif.position) private var objectifs: [Objectif]

    @State private var store = ReglagesStore()
    @State private var positionAffichee: Int?
    @State private var maintenant = Date()

    private let battement = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var service: ServiceDeBlocs {
        ServiceDeBlocs(
            horloge: HorlogeSysteme(),
            notifications: PlanificateurSysteme()
        ) { store.reglages }
    }

    var body: some View {
        TabView(selection: $positionAffichee) {
            ForEach(blocs) { bloc in
                VueBlocWatch(
                    bloc: bloc,
                    objectif: objectifs.first { $0.position == bloc.position },
                    maintenant: maintenant
                ) {
                    service.basculer(bloc, parmi: blocs)
                }
                .tag(bloc.position as Int?)
            }
        }
        .tabViewStyle(.page)  // balayage horizontal, avec l'indicateur de page (SPECS §7.1)
        .onAppear { positionAffichee = Journee.blocAOuvrir(parmi: blocs)?.position }
        .onReceive(battement) { instant in
            maintenant = instant
            service.rafraichir(blocs)
        }
        .onChange(of: phase) { _, nouvelle in
            guard nouvelle == .active else { return }
            maintenant = Date()
            service.rafraichir(blocs)
        }
    }
}
