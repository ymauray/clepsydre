// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ClepsydreCore",
    defaultLocalization: "fr",
    // macOS n'est pas une plateforme cible : elle est déclarée pour que `swift test`
    // s'exécute en ligne de commande sans passer par un simulateur.
    platforms: [.iOS(.v17), .watchOS(.v10), .macOS(.v14)],
    products: [
        .library(name: "ClepsydreCore", targets: ["ClepsydreCore"])
    ],
    targets: [
        .target(name: "ClepsydreCore"),
        // Outil de développement : régénère l'icône à partir du dessin de la clepsydre.
        // Ne fait pas partie de l'app.
        .executableTarget(name: "IcôneClepsydre", dependencies: ["ClepsydreCore"]),
        .testTarget(name: "ClepsydreCoreTests", dependencies: ["ClepsydreCore"])
    ]
)
