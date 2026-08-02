import Foundation

/// L'état d'un bloc au cours de la journée.
///
/// `termine` est définitif : aucune transition n'en fait sortir avant le lendemain
/// (voir SPECS §4 et §9).
public enum EtatBloc: String, Codable, Sendable, CaseIterable {
    case enAttente
    case enCours
    case enPause
    case termine
}
