import ClepsydreCore
import SwiftData
import SwiftUI

/// L'écran principal : les quatre blocs, présentés ensemble (SPECS §5.2).
struct VueJournee: View {
    @Environment(\.modelContext) private var contexte
    @Environment(\.scenePhase) private var phase
    @Environment(\.colorScheme) private var themeDuSysteme

    @Query(sort: \Bloc.position) private var blocs: [Bloc]
    @Query(sort: \Objectif.position) private var objectifs: [Objectif]

    @State private var store = ReglagesStore()
    @State private var maintenant = Date()
    @State private var blocEnEdition: Bloc?
    #if DEBUG
    @State private var tapsRapides: (bloc: UUID, compte: Int, date: Date)?
    #endif

    private let planificateur = PlanificateurSysteme()
    /// Rafraîchit l'affichage chaque seconde. Ce n'est jamais la source de vérité (SPECS §6).
    private let battement = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var service: ServiceDeBlocs {
        ServiceDeBlocs(horloge: HorlogeSysteme(), notifications: planificateur) { store.reglages }
    }

    /// Le thème effectivement appliqué : celui choisi par l'utilisateur, sinon celui du
    /// système tant qu'il n'a rien choisi.
    private var enSombre: Bool {
        store.reglages.themeSombre ?? (themeDuSysteme == .dark)
    }

    /// Double tap sur le titre : on fixe l'inverse de ce qui est affiché, et ça reste.
    private func basculerLeTheme() {
        store.reglages.themeSombre = !enSombre
    }

    var body: some View {
        grille
            .preferredColorScheme(store.reglages.themeSombre.map { $0 ? .dark : .light })
            .animation(.smooth, value: enSombre)
            .task { await demarrage() }
        .onReceive(battement) { instant in
            maintenant = instant
            service.rafraichir(blocs)
        }
        .onChange(of: phase) { _, nouvelle in
            guard nouvelle == .active else { return }
            maintenant = Date()
            preparerLaJourneeSiNecessaire()
            service.rafraichir(blocs)
        }
        .sheet(item: $blocEnEdition) { bloc in
            VueOptionsBloc(bloc: bloc, objectif: objectif(pour: bloc), store: store)
        }
    }

    private var grille: some View {
        GeometryReader { geometrie in
            let paysage = geometrie.size.width > geometrie.size.height
            let colonnes = paysage ? 4 : 2
            let lignes = paysage ? 1 : 2
            let cote = coteDuCarre(dans: geometrie.size, colonnes: colonnes, lignes: lignes)

            // Deux bandes de poids égal encadrent la grille : les blocs se retrouvent
            // centrés dans l'écran, et le titre au milieu de l'espace qui reste au-dessus.
            VStack(spacing: 0) {
                VueEntete(
                    avancement: Journee.avancementDeLaJournee(a: maintenant),
                    basculerLeTheme: basculerLeTheme
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                LazyVGrid(
                    columns: Array(
                        repeating: GridItem(.fixed(cote), spacing: Self.marge),
                        count: colonnes
                    ),
                    spacing: Self.marge
                ) {
                    ForEach(blocs) { bloc in
                        VueBloc(
                            bloc: bloc,
                            objectif: objectif(pour: bloc),
                            maintenant: maintenant,
                            couleur: PaletteBlocs.couleur(
                                pour: bloc.position,
                                sombre: enSombre
                            )
                        )
                            .frame(width: cote, height: cote)
                            .onTapGesture { tape(bloc) }
                            .onLongPressGesture { blocEnEdition = bloc }
                    }
                }

                Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.smooth, value: paysage)
        }
    }

    /// Un tap : on lance ou on met en pause.
    private func tape(_ bloc: Bloc) {
        #if DEBUG
        if trappeDeReinitialisation(bloc) { return }
        #endif
        service.basculer(bloc, parmi: blocs, titreObjectif: objectif(pour: bloc)?.titre ?? "")
    }

    #if DEBUG
    /// Quatre taps rapides sur un même bloc le remettent à zéro, à l'arrêt.
    ///
    /// Trappe de développement non documentée, pour ne pas attendre 45 minutes en testant.
    /// Le compte se fait à la main plutôt qu'avec `onTapGesture(count: 4)` : ce dernier
    /// obligerait SwiftUI à retarder chaque tap simple le temps de lever l'ambiguïté, et le
    /// lancement d'un bloc doit rester instantané.
    private func trappeDeReinitialisation(_ bloc: Bloc) -> Bool {
        let maintenant = Date()
        let suite = tapsRapides.map { $0.bloc == bloc.id && maintenant.timeIntervalSince($0.date) < 0.4 } ?? false
        let compte = suite ? (tapsRapides?.compte ?? 0) + 1 : 1
        tapsRapides = (bloc: bloc.id, compte: compte, date: maintenant)

        guard compte >= 4 else { return false }
        tapsRapides = nil
        planificateur.annulerFinDeBloc(identifiant: bloc.id.uuidString)
        bloc.reinitialiserPourDeveloppement(duree: store.reglages.duree(pour: bloc.position))
        return true
    }
    #endif

    /// La même marge partout : sur les bords et entre les blocs. Tout ce qui reste est
    /// pris par les carrés, aussi gros que la place le permet (SPECS §7.1).
    private static let marge: CGFloat = 20

    /// Hauteur réservée au titre de part et d'autre de la grille, pour que les carrés ne
    /// viennent pas le chasser en paysage.
    private static let bandeDuTitre: CGFloat = 64

    private func coteDuCarre(dans taille: CGSize, colonnes: Int, lignes: Int) -> CGFloat {
        let parLargeur =
            (taille.width - CGFloat(colonnes + 1) * Self.marge) / CGFloat(colonnes)
        let hauteurUtile = taille.height - 2 * Self.bandeDuTitre
        let parHauteur =
            (hauteurUtile - CGFloat(lignes - 1) * Self.marge) / CGFloat(lignes)
        return max(0, min(parLargeur, parHauteur))
    }

    private func objectif(pour bloc: Bloc) -> Objectif? {
        objectifs.first { $0.position == bloc.position }
    }

    private func demarrage() async {
        preparerLaJourneeSiNecessaire()
        _ = await planificateur.demanderAutorisation()
        service.appliquerRappelMatinal()
        service.rafraichir(blocs)
    }

    /// Crée les quatre blocs au premier lancement, puis bascule la journée au passage à
    /// minuit : blocs à zéro, objectifs de la veille repris (SPECS §5.4).
    private func preparerLaJourneeSiNecessaire() {
        let aujourdhui = Calendar.current.startOfDay(for: Date())

        if blocs.isEmpty {
            for position in 0..<Clepsydre.nombreDeBlocs {
                contexte.insert(
                    Bloc(position: position, duree: store.reglages.duree(pour: position))
                )
            }
        }

        let dejaAJour = objectifs.contains { $0.date == aujourdhui }
        guard !dejaAJour else { return }

        let veille = objectifs.filter { $0.date < aujourdhui }
        let repris = Journee.commencer(
            aujourdhui,
            blocs: blocs,
            objectifsDeLaVeille: veille,
            reglages: store.reglages
        )
        for objectif in repris { contexte.insert(objectif) }
        // La v1 n'expose pas d'historique : on ne garde que la veille, le temps de la reprise.
        for ancien in objectifs where ancien.date < aujourdhui.addingTimeInterval(-86_400) {
            contexte.delete(ancien)
        }
    }
}
