import UIKit

/// Retours haptiques.
///
/// On passe par `UIImpactFeedbackGenerator` plutôt que par `sensoryFeedback` de SwiftUI :
/// ce dernier ne prépare pas le moteur, et un moteur non préparé met quelques dizaines de
/// millisecondes à démarrer — le coup part alors mou et en retard.
enum Haptique {
    /// Un « clac » franc en deux temps, pour confirmer une action de développement.
    @MainActor
    static func confirmation() {
        let moteur = UIImpactFeedbackGenerator(style: .rigid)
        moteur.prepare()
        moteur.impactOccurred(intensity: 1)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.09) {
            moteur.impactOccurred(intensity: 1)
        }
    }
}
