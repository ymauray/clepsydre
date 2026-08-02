import SwiftUI

/// Une clepsydre dessinée en vectoriel : le sable quitte le bulbe du haut pour former un
/// tas en bas. Les deux volumes se répondent — ce qui est parti d'un côté est arrivé de
/// l'autre.
public struct VueClepsydre: View {
    /// 1 = le sable est intact en haut, 0 = tout est passé en bas.
    public var sableRestant: Double
    /// Épaisseur du verre. À donner en proportion de la taille du dessin : un trait fixe
    /// disparaît quand on agrandit la clepsydre pour en faire une icône.
    public var epaisseur: CGFloat

    public init(sableRestant: Double, epaisseur: CGFloat = 1.5) {
        self.sableRestant = sableRestant
        self.epaisseur = epaisseur
    }

    public var body: some View {
        ZStack {
            // Le sable est dessiné large puis découpé par le verre : c'est le contour qui
            // lui donne sa forme, on n'a donc jamais à redessiner les bulbes deux fois.
            Sable(restant: sableRestant)
                .fill(.tint.opacity(0.75))
                .clipShape(Verre())
            Verre()
                .stroke(
                    .secondary,
                    style: StrokeStyle(lineWidth: epaisseur, lineCap: .round, lineJoin: .round)
                )
        }
        .animation(.smooth, value: sableRestant)
    }
}

/// Le contour : deux bulbes qui s'évasent en courbe depuis un col étroit, fermés par un
/// plateau en haut et en bas.
public struct Verre: Shape {
    public init() {}

    public func path(in rect: CGRect) -> Path {
        var trace = Path()
        let colX = rect.width * 0.05  // demi-largeur du goulot
        let colY = rect.height * 0.035  // demi-hauteur du goulot, qui lui donne son épaisseur
        let renflement = rect.height * 0.30  // ce qui arrondit les bulbes
        let milieu = rect.midY

        trace.move(to: CGPoint(x: rect.minX, y: rect.minY))
        trace.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        // Flanc droit du bulbe haut, puis le goulot, puis le flanc du bulbe bas.
        trace.addCurve(
            to: CGPoint(x: rect.midX + colX, y: milieu - colY),
            control1: CGPoint(x: rect.maxX, y: rect.minY + renflement),
            control2: CGPoint(x: rect.midX + colX, y: milieu - colY - renflement * 0.55)
        )
        trace.addLine(to: CGPoint(x: rect.midX + colX, y: milieu + colY))
        trace.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY),
            control1: CGPoint(x: rect.midX + colX, y: milieu + colY + renflement * 0.55),
            control2: CGPoint(x: rect.maxX, y: rect.maxY - renflement)
        )
        trace.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        trace.addCurve(
            to: CGPoint(x: rect.midX - colX, y: milieu + colY),
            control1: CGPoint(x: rect.minX, y: rect.maxY - renflement),
            control2: CGPoint(x: rect.midX - colX, y: milieu + colY + renflement * 0.55)
        )
        trace.addLine(to: CGPoint(x: rect.midX - colX, y: milieu - colY))
        trace.addCurve(
            to: CGPoint(x: rect.minX, y: rect.minY),
            control1: CGPoint(x: rect.midX - colX, y: milieu - colY - renflement * 0.55),
            control2: CGPoint(x: rect.minX, y: rect.minY + renflement)
        )
        trace.closeSubpath()
        return trace
    }
}

/// Le sable : ce qui reste en haut, le tas qui monte en bas, et le filet qui passe le col.
///
/// Les deux surfaces bougent en **aire**, pas en hauteur : les bulbes s'évasent vers les
/// extrémités, donc à hauteur égale les tranches n'ont pas le même volume. Faire varier la
/// hauteur linéairement donnerait un écoulement qui semble s'emballer à la fin — d'où la
/// racine carrée, qui rend la vidange régulière à l'œil.
public struct Sable: Shape {
    public var restant: Double

    public init(restant: Double) { self.restant = restant }

    public var animatableData: Double {
        get { restant }
        set { restant = newValue }
    }

    public func path(in rect: CGRect) -> Path {
        let part = sqrt(min(1, max(0, restant)))
        let demiHauteur = rect.height / 2
        let creux = rect.height * 0.045  // l'entonnoir en haut, le monticule en bas
        let debord = rect.width  // le tracé déborde : le verre se charge de le découper
        var trace = Path()

        // Ce qui reste en haut, la surface se creusant en entonnoir vers le col.
        if part > 0 {
            let surface = rect.midY - demiHauteur * part
            trace.move(to: CGPoint(x: rect.minX - debord, y: surface))
            trace.addQuadCurve(
                to: CGPoint(x: rect.maxX + debord, y: surface),
                control: CGPoint(x: rect.midX, y: surface + 2 * creux)
            )
            trace.addLine(to: CGPoint(x: rect.maxX + debord, y: rect.midY))
            trace.addLine(to: CGPoint(x: rect.minX - debord, y: rect.midY))
            trace.closeSubpath()
        }

        // Le tas du bas, bombé au centre là où le filet retombe.
        if part < 1 {
            let surface = rect.midY + demiHauteur * part
            trace.move(to: CGPoint(x: rect.minX - debord, y: surface))
            trace.addQuadCurve(
                to: CGPoint(x: rect.maxX + debord, y: surface),
                control: CGPoint(x: rect.midX, y: surface - 2 * creux)
            )
            trace.addLine(to: CGPoint(x: rect.maxX + debord, y: rect.maxY))
            trace.addLine(to: CGPoint(x: rect.minX - debord, y: rect.maxY))
            trace.closeSubpath()
        }

        // Le filet qui tombe du col vers le tas, tant qu'il reste du sable à faire passer.
        if part > 0, part < 1 {
            let largeur = rect.width * 0.02
            trace.addRect(
                CGRect(
                    x: rect.midX - largeur,
                    y: rect.midY,
                    width: largeur * 2,
                    height: demiHauteur * part
                )
            )
        }

        return trace
    }
}
