import Foundation
import SwiftData

/// Un des quatre objectifs d'une journée.
///
/// Pas de champ `accompli` : l'accomplissement se lit dans l'état du bloc de même
/// position (SPECS §3).
@Model
public final class Objectif {
    public var id: UUID
    public var titre: String
    /// Jour auquel l'objectif appartient, normalisé à minuit.
    public var date: Date
    /// 0…3, l'emplacement occupé.
    public var position: Int

    public init(id: UUID = UUID(), titre: String = "", date: Date, position: Int) {
        self.id = id
        self.titre = titre
        self.date = date
        self.position = position
    }

    public var estVide: Bool {
        titre.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
