import Foundation

/// Les règles qui portent sur la journée entière, plutôt que sur un bloc isolé.
public enum Journee {
    /// Lance un bloc en mettant en pause celui qui tournait.
    ///
    /// Un seul timer peut être actif à la fois (SPECS §5.2), et l'ordre de départ des blocs
    /// est libre (SPECS §9).
    @discardableResult
    public static func demarrer(_ bloc: Bloc, parmi blocs: [Bloc], a instant: Date) -> Bool {
        guard bloc.peutDemarrer else { return false }
        for autre in blocs where autre.id != bloc.id {
            autre.mettreEnPause(a: instant)
        }
        return bloc.demarrer(a: instant)
    }

    /// Un tap sur un bloc : il démarre, ou il se met en pause s'il tournait déjà.
    @discardableResult
    public static func basculer(_ bloc: Bloc, parmi blocs: [Bloc], a instant: Date) -> Bool {
        if bloc.etat == .enCours {
            return bloc.mettreEnPause(a: instant)
        }
        return demarrer(bloc, parmi: blocs, a: instant)
    }

    /// Le bloc actuellement en cours, s'il y en a un.
    public static func blocEnCours(parmi blocs: [Bloc]) -> Bloc? {
        blocs.first { $0.etat == .enCours }
    }

    /// Rattrape les blocs arrivés à échéance pendant que l'app était fermée.
    /// Renvoie les blocs qui viennent de passer à `termine`.
    @discardableResult
    public static func rafraichir(_ blocs: [Bloc], a instant: Date) -> [Bloc] {
        blocs.filter { $0.terminerSiEchu(a: instant) }
    }

    /// Le bloc à présenter en premier sur la Watch : celui en cours, sinon le premier
    /// non terminé (SPECS §7.1).
    public static func blocAOuvrir(parmi blocs: [Bloc]) -> Bloc? {
        let ordonnes = blocs.sorted { $0.position < $1.position }
        return blocEnCours(parmi: ordonnes)
            ?? ordonnes.first { $0.etat != .termine }
            ?? ordonnes.first
    }

    /// Part de la journée civile déjà écoulée, entre 0 et 1.
    ///
    /// C'est l'heure qu'il est, pas l'avancement du travail : la clepsydre de l'en-tête
    /// rappelle que le jour s'écoule de toute façon, qu'on s'en serve ou non.
    public static func avancementDeLaJournee(
        a instant: Date,
        calendrier: Calendar = .current
    ) -> Double {
        let debut = calendrier.startOfDay(for: instant)
        guard let lendemain = calendrier.date(byAdding: .day, value: 1, to: debut) else {
            return 0
        }
        let duree = lendemain.timeIntervalSince(debut)
        guard duree > 0 else { return 0 }
        return min(1, max(0, instant.timeIntervalSince(debut) / duree))
    }

    /// Prépare la journée `date` : les blocs repartent à zéro avec les durées globales,
    /// et les objectifs de la veille sont repris tels quels (SPECS §5.4).
    ///
    /// Les objectifs de la veille ne sont pas déplacés mais **copiés** : la journée
    /// précédente reste intacte en base.
    public static func commencer(
        _ date: Date,
        blocs: [Bloc],
        objectifsDeLaVeille: [Objectif],
        reglages: Reglages
    ) -> [Objectif] {
        for bloc in blocs.sorted(by: { $0.position < $1.position }) {
            bloc.preparerNouveauJour(duree: reglages.duree(pour: bloc.position))
        }

        let titres = Dictionary(
            objectifsDeLaVeille.map { ($0.position, $0.titre) },
            uniquingKeysWith: { premier, _ in premier }
        )
        return (0..<Clepsydre.nombreDeBlocs).map { position in
            Objectif(titre: titres[position] ?? "", date: date, position: position)
        }
    }
}
