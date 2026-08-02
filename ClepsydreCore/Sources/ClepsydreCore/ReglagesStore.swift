import Foundation
import Observation

/// Les réglages sont globaux et peu nombreux : `UserDefaults` suffit, SwiftData est réservé
/// aux objectifs et aux blocs.
@Observable
public final class ReglagesStore {
    private static let cle = "reglages"
    private let defaults: UserDefaults

    public var reglages: Reglages {
        didSet { enregistrer() }
    }

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let donnees = defaults.data(forKey: Self.cle),
           let decodees = try? JSONDecoder().decode(Reglages.self, from: donnees) {
            reglages = decodees
        } else {
            reglages = Reglages()
        }
    }

    private func enregistrer() {
        guard let donnees = try? JSONEncoder().encode(reglages) else { return }
        defaults.set(donnees, forKey: Self.cle)
    }
}
