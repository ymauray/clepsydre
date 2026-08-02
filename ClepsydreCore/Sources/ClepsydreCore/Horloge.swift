import Foundation

/// Source de l'instant présent.
///
/// Le décompte n'utilise jamais `Date()` directement : en passant par une horloge
/// injectable, un test peut simuler « trois heures plus tard » sans attendre.
public protocol Horloge: Sendable {
    var maintenant: Date { get }
}

/// L'horloge réelle, utilisée par l'app.
public struct HorlogeSysteme: Horloge {
    public init() {}
    public var maintenant: Date { Date() }
}

/// Une horloge que l'on avance à la main, pour les tests.
public final class HorlogeFigee: Horloge, @unchecked Sendable {
    private let verrou = NSLock()
    private var instant: Date

    public init(_ instant: Date = Date(timeIntervalSince1970: 0)) {
        self.instant = instant
    }

    public var maintenant: Date {
        verrou.lock()
        defer { verrou.unlock() }
        return instant
    }

    public func avancer(de intervalle: TimeInterval) {
        verrou.lock()
        defer { verrou.unlock() }
        instant += intervalle
    }
}
