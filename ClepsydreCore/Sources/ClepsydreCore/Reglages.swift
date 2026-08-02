import Foundation

/// Les réglages de l'app. Les durées sont **globales** et valent tous les jours (SPECS §9).
public struct Reglages: Codable, Equatable, Sendable {
    /// Les quatre durées, dans l'ordre des positions 0…3.
    public var durees: [TimeInterval]
    public var notificationsDeFinActivees: Bool
    public var rappelMatinalActive: Bool
    /// Heure du rappel matinal, en heures et minutes.
    public var heureDuRappel: DateComponents
    /// `nil` tant que l'utilisateur n'a rien choisi : on suit alors le réglage du système.
    /// Le double tap sur le titre fixe une valeur explicite (SPECS §7.3).
    public var themeSombre: Bool?

    public static let dureesParDefaut: [TimeInterval] = [5 * 60, 15 * 60, 30 * 60, 45 * 60]

    public init(
        durees: [TimeInterval] = Reglages.dureesParDefaut,
        notificationsDeFinActivees: Bool = true,
        rappelMatinalActive: Bool = true,
        heureDuRappel: DateComponents = DateComponents(hour: 8, minute: 0),
        themeSombre: Bool? = nil
    ) {
        self.durees = durees
        self.notificationsDeFinActivees = notificationsDeFinActivees
        self.rappelMatinalActive = rappelMatinalActive
        self.heureDuRappel = heureDuRappel
        self.themeSombre = themeSombre
    }

    public func duree(pour position: Int) -> TimeInterval {
        durees.indices.contains(position) ? durees[position] : Reglages.dureesParDefaut[position]
    }
}

public enum Clepsydre {
    /// La contrainte est la fonctionnalité (SPECS §2).
    public static let nombreDeBlocs = 4
}
