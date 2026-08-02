import ClepsydreCore
import SwiftData
import SwiftUI

/// L'écran principal : les quatre blocs, présentés ensemble (SPECS §5.2).
struct VueJournee: View {
    let routeur: RouteurDeNotifications

    init(routeur: RouteurDeNotifications) {
        self.routeur = routeur
        let planificateur = PlanificateurSysteme()
        _autorisations = State(initialValue: AutorisationNotifications(planificateur: planificateur))
    }

    @Environment(\.modelContext) private var contexte
    @Environment(\.scenePhase) private var phase
    @Environment(\.colorScheme) private var themeDuSysteme

    @Query(sort: \Bloc.position) private var blocs: [Bloc]
    @Query(sort: \Objectif.position) private var objectifs: [Objectif]

    @State private var store = ReglagesStore()
    @State private var maintenant = Date()
    @State private var presentation: Presentation?

    /// Un seul écran modal à la fois. Deux modificateurs `.sheet` sur une même vue relèvent
    /// du comportement non défini — d'où un état unique plutôt que deux booléens.
    private enum Presentation: Identifiable, Hashable {
        case rituel
        case reglages
        case options(Bloc.ID)

        var id: Self { self }
    }
    #if DEBUG
    @State private var tapsRapides: (bloc: UUID, compte: Int, date: Date)?
    #endif

    private let planificateur = PlanificateurSysteme()
    @State private var autorisations: AutorisationNotifications
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
            // Le bouton est ancré au coin de l'écran, pas à la bande du titre : sur un iPad,
            // cette bande fait plusieurs centaines de points de haut et le bouton flotterait
            // au milieu de nulle part.
            .overlay(alignment: .topTrailing) { boutonDesReglages }
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
        .sheet(item: $presentation) { quoi in
            switch quoi {
            case .reglages:
                VueReglages(
                    store: store,
                    blocs: blocs,
                    autorisations: autorisations,
                    appliquerLeRappel: { service.appliquerRappelMatinal() }
                )
            case .rituel:
                VueRituel(objectifs: objectifs, reglages: store.reglages) {
                    demanderLAutorisationSiLeMomentSyPrete(titreObjectif: "")
                }
            case .options(let identifiant):
                if let bloc = blocs.first(where: { $0.id == identifiant }) {
                    VueOptionsBloc(bloc: bloc, objectif: objectif(pour: bloc), store: store)
                }
            }
        }
        // Un tap sur le rappel de 8h ouvre directement la saisie (SPECS §5.1).
        .onChange(of: routeur.rituelDemande) { _, demande in
            guard demande else { return }
            routeur.rituelDemande = false
            ouvrirLeRituel()
        }
    }

    /// Le seul élément d'interface non essentiel de l'écran : discret par la taille, mais
    /// pas par la couleur — des réglages qu'on ne trouve pas ne servent à rien.
    private var boutonDesReglages: some View {
        Button {
            presentation = .reglages
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.primary)
                .padding(14)
                .contentShape(.rect)
        }
        // Sans ce style, le bouton impose la teinte d'accent par-dessus la couleur demandée.
        .buttonStyle(.plain)
        .accessibilityLabel("Réglages")
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
                            .onLongPressGesture { presentation = .options(bloc.id) }
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
        // Le bloc démarre tout de suite : on ne fait pas attendre l'utilisateur derrière une
        // fenêtre système. L'autorisation est demandée dans la foulée, et la notification
        // reposée une fois la réponse connue.
        let titre = objectif(pour: bloc)?.titre ?? ""
        service.basculer(bloc, parmi: blocs, titreObjectif: titre)
        demanderLAutorisationSiLeMomentSyPrete(titreObjectif: titre)
    }

    /// Demande l'autorisation au premier moment où une notification servirait vraiment.
    private func demanderLAutorisationSiLeMomentSyPrete(titreObjectif: String) {
        guard autorisations.statut == .notDetermined else { return }
        Task {
            guard await autorisations.demanderSiNecessaire() else { return }
            service.reprogrammerLeBlocEnCours(parmi: blocs, titreObjectif: titreObjectif)
            service.appliquerRappelMatinal()
        }
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

        // Et on rejoue le rappel du matin dans dix secondes : de quoi tuer l'app et refaire
        // le parcours « notification → rituel » autant de fois qu'on veut.
        store.reglages.dernierRituelPropose = nil
        planificateur.rejouerLeRappelMatinal()
        Haptique.confirmation()
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

    /// Ouvre l'écran de saisie et note qu'on l'a proposé aujourd'hui.
    private func ouvrirLeRituel() {
        // Rien à éditer tant que les objectifs du jour n'existent pas.
        guard !objectifs.isEmpty else { return }
        store.reglages.dernierRituelPropose = Date()
        presentation = .rituel
    }

    private func demarrage() async {
        preparerLaJourneeSiNecessaire()

        // À la première ouverture de la journée, on propose le rituel — une seule fois.
        // On laisse d'abord la vue s'installer : présenter une feuille pendant que la scène
        // se connecte encore, c'est demander des ennuis.
        if Journee.doitProposerLeRituel(
            a: Date(),
            derniereProposition: store.reglages.dernierRituelPropose
        ) || routeur.rituelDemande {
            routeur.rituelDemande = false
            try? await Task.sleep(for: .milliseconds(350))
            ouvrirLeRituel()
        }

        // On ne demande rien au lancement : on constate seulement où on en est (SPECS §5.5).
        await autorisations.actualiser()
        if autorisations.accordee { service.appliquerRappelMatinal() }
        service.rafraichir(blocs)

        #if DEBUG
        // `NSLog` et non `print` : seule la sortie du système de journalisation est relayée
        // jusqu'à la console de `devicectl`.
        NSLog("[Clepsydre] autorisation : %d", autorisations.statut.rawValue)
        NSLog("[Clepsydre] programmé :\n%@", await planificateur.decrireCeQuiEstProgramme())
        #endif
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
