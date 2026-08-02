import SwiftUI

/// Une couleur par bloc.
///
/// Les quatre teintes sont espacées sur le cercle chromatique pour qu'on reconnaisse un bloc
/// à sa couleur avant même d'en lire le titre. Elles restent rabattues en saturation : on
/// veut quatre voix distinctes, pas quatre néons — la §7 demande du calme.
///
/// Chaque teinte a une variante sombre, un peu plus claire et moins saturée : une couleur
/// pensée pour du blanc paraît sale sur fond noir.
public enum PaletteBlocs {
    public static func couleur(pour position: Int, sombre: Bool) -> Color {
        let teintes = sombre ? Self.enModeSombre : Self.enModeClair
        return teintes[((position % teintes.count) + teintes.count) % teintes.count]
    }

    /// Terre cuite, ambre, sauge, prune.
    private static let enModeClair: [Color] = [
        Color(red: 0.76, green: 0.38, blue: 0.25),
        Color(red: 0.72, green: 0.53, blue: 0.18),
        Color(red: 0.28, green: 0.53, blue: 0.42),
        Color(red: 0.42, green: 0.36, blue: 0.62)
    ]

    private static let enModeSombre: [Color] = [
        Color(red: 0.85, green: 0.48, blue: 0.35),
        Color(red: 0.84, green: 0.65, blue: 0.33),
        Color(red: 0.40, green: 0.68, blue: 0.55),
        Color(red: 0.57, green: 0.50, blue: 0.78)
    ]

    /// Le bleu de la clepsydre, qui ne bouge pas : c'est la signature de l'app, pas un bloc.
    public static let clepsydre = Color(red: 0.30, green: 0.45, blue: 0.62)
}
