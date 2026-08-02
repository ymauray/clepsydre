import ClepsydreCore
import SwiftUI

/// Le titre de l'app, précédé d'une clepsydre qui se vide au fil de la journée.
struct VueEntete: View {
    /// Part de la journée déjà écoulée, entre 0 et 1.
    let avancement: Double
    /// Double tap sur le titre : bascule le thème (SPECS §7.3).
    let basculerLeTheme: () -> Void
    var body: some View {
        HStack(spacing: 14) {
            VueClepsydre(sableRestant: 1 - avancement)
                .tint(PaletteBlocs.clepsydre)
                .frame(width: 26, height: 34)

            Text("Clepsydre")
                .font(.system(.title2, design: .serif))
                .textCase(.uppercase)
                .tracking(6)
                .foregroundStyle(.secondary)
        }
        .contentShape(.rect)
        .onTapGesture(count: 2, perform: basculerLeTheme)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Clepsydre")
        .accessibilityValue("Journée écoulée à \(Int(avancement * 100)) pour cent")
        .accessibilityAddTraits(.isButton)
        .accessibilityHint("Toucher deux fois pour changer de thème")
    }
}

#Preview {
    VStack(spacing: 30) {
        VueEntete(avancement: 0, basculerLeTheme: {})
        VueEntete(avancement: 0.4, basculerLeTheme: {})
        VueEntete(avancement: 1, basculerLeTheme: {})
    }
}
