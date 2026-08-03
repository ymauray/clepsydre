#if os(iOS)
import AppIntents
import Foundation

/// Le geste que le bouton de la Live Activity déclenche.
///
/// L'intention vit dans le module partagé parce que l'extension a besoin du type pour
/// compiler son bouton, et l'app pour l'exécuter. Elle ne fait rien elle-même : elle appelle
/// le geste que l'app installe au lancement, ce qui évite d'ouvrir une seconde base SwiftData
/// depuis l'extension.
public enum ActionsDuBloc {
    /// Installé par l'app au lancement. Reçoit l'identifiant du bloc à basculer.
    @MainActor public static var basculer: ((String) -> Void)?
}

/// `LiveActivityIntent` s'exécute **dans le processus de l'app**, et non dans celui de
/// l'extension : c'est ce qui permet de toucher au modèle. iOS réveille l'app en arrière-plan
/// si besoin.
@available(iOS 17.0, *)
public struct BasculerLeBloc: LiveActivityIntent {
    public static let title: LocalizedStringResource = "Lancer ou mettre en pause le bloc"

    @Parameter(title: "Bloc")
    public var identifiant: String

    public init() {
        identifiant = ""
    }

    public init(identifiant: String) {
        self.identifiant = identifiant
    }

    public func perform() async throws -> some IntentResult {
        let identifiant = identifiant
        await MainActor.run { ActionsDuBloc.basculer?(identifiant) }
        return .result()
    }
}
#endif
