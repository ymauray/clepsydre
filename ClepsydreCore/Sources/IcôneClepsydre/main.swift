import AppKit
import ClepsydreCore
import SwiftUI
import UniformTypeIdentifiers

/// Génère l'icône de l'app à partir du même dessin que l'en-tête.
///
/// Usage : `swift run IcôneClepsydre <chemin.png> [heure] [montre]`
/// L'heure par défaut est 15h — la clepsydre est alors nettement entamée sans être vide,
/// ce qui donne à voir les deux tas et le filet.
/// Le troisième argument `montre` resserre le dessin : watchOS rogne l'icône en cercle, et
/// une clepsydre calée sur la pleine largeur y perdrait ses bulbes.

/// L'icône : la clepsydre seule sur un fond calme, sans texte.
struct IcôneClepsydre: View {
    let heure: Double
    /// Cadrage resserré pour le rognage circulaire de watchOS.
    let pourLaMontre: Bool

    private var sableRestant: Double { 1 - heure / 24 }
    private var largeur: CGFloat { pourLaMontre ? 360 : 470 }
    private var hauteur: CGFloat { pourLaMontre ? 475 : 620 }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.16, green: 0.24, blue: 0.33),
                    Color(red: 0.09, green: 0.14, blue: 0.20)
                ],
                startPoint: .top,
                endPoint: .bottom
            )

            VueClepsydre(sableRestant: sableRestant, epaisseur: 14)
                .tint(Color(red: 0.85, green: 0.78, blue: 0.60))
                .foregroundStyle(Color(red: 0.85, green: 0.87, blue: 0.90))
                .frame(width: largeur, height: hauteur)
        }
        .frame(width: 1024, height: 1024)
    }
}

let arguments = CommandLine.arguments
guard arguments.count >= 2 else {
    FileHandle.standardError.write(
        Data("usage : IcôneClepsydre <chemin.png> [heure]\n".utf8)
    )
    exit(1)
}
let destination = URL(fileURLWithPath: arguments[1])
let heure = arguments.count >= 3 ? (Double(arguments[2]) ?? 15) : 15
let pourLaMontre = arguments.count >= 4 && arguments[3] == "montre"

let rendu = await MainActor.run { () -> CGImage? in
    let moteur = ImageRenderer(
        content: IcôneClepsydre(heure: heure, pourLaMontre: pourLaMontre)
    )
    moteur.scale = 1
    return moteur.cgImage
}

guard let image = rendu else {
    FileHandle.standardError.write(Data("le rendu a échoué\n".utf8))
    exit(1)
}

guard
    let sortie = CGImageDestinationCreateWithURL(
        destination as CFURL, UTType.png.identifier as CFString, 1, nil
    )
else {
    FileHandle.standardError.write(Data("écriture impossible\n".utf8))
    exit(1)
}
CGImageDestinationAddImage(sortie, image, nil)
guard CGImageDestinationFinalize(sortie) else {
    FileHandle.standardError.write(Data("finalisation impossible\n".utf8))
    exit(1)
}

print("icône écrite : \(destination.path) (heure : \(heure)h\(pourLaMontre ? ", cadrage montre" : ""))")
