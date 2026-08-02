import Foundation

/// L'échelle des durées réglables : **1 minute, puis 5, 10, 15…** jusqu'à trois heures.
///
/// Un simple pas de 5 partant de 1 donnerait 1, 6, 11, 16 — des durées qu'on ne se fixe
/// jamais. La minute isolée sert de plus petit cran possible ; au-delà, on raisonne en
/// multiples de 5.
public enum EchelleDesDurees {
    public static let minimum = 1
    public static let maximum = 180
    private static let pas = 5

    public static func suivante(apres minutes: Int) -> Int {
        guard minutes >= pas else { return pas }
        return min(maximum, (minutes / pas) * pas + pas)
    }

    public static func precedente(avant minutes: Int) -> Int {
        guard minutes > pas else { return minimum }
        // Le `- 1` fait redescendre au cran inférieur même quand on part d'un multiple exact.
        return max(pas, ((minutes - 1) / pas) * pas)
    }
}
