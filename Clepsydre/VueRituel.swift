import ClepsydreCore
import SwiftUI

/// Le rituel du matin : quatre objectifs, quatre durées (SPECS §5.1).
///
/// L'étape est **passable** — on peut fermer sans rien écrire et nommer ses objectifs plus
/// tard, par appui long sur un bloc. Rien n'est obligatoire, rien n'est reproché.
struct VueRituel: View {
    @Environment(\.dismiss) private var fermer
    @Environment(\.colorScheme) private var theme

    let objectifs: [Objectif]
    let reglages: Reglages
    /// Appelé quand l'utilisateur valide ses objectifs — bon moment pour demander
    /// l'autorisation d'envoyer des notifications (SPECS §5.5).
    var objectifsValides: () -> Void = {}

    /// Saisies locales : on n'écrit dans le modèle qu'à la fermeture, pour qu'un aller-retour
    /// dans l'écran ne laisse pas de titres à moitié tapés.
    @State private var titres: [String] = Array(repeating: "", count: Clepsydre.nombreDeBlocs)
    @FocusState private var champActif: Int?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    Text("Quatre choses aujourd'hui, et leur temps.")
                        .font(.system(.title3, design: .serif))
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)

                    ForEach(0..<Clepsydre.nombreDeBlocs, id: \.self) { position in
                        champ(pour: position)
                    }
                }
                .padding(24)
            }
            .navigationTitle("Le rituel du matin")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    // L'étape est passable, et ça se voit.
                    Button("Plus tard") { fermer() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Commencer") {
                        enregistrer()
                        objectifsValides()
                        fermer()
                    }
                    .fontWeight(.semibold)
                }
                ToolbarItem(placement: .keyboard) {
                    Button("Suivant") { champSuivant() }
                }
            }
        }
        .onAppear {
            titres = (0..<Clepsydre.nombreDeBlocs).map { position in
                objectifs.first { $0.position == position }?.titre ?? ""
            }
        }
        .onDisappear(perform: enregistrer)
    }

    /// Un champ par emplacement, la durée du bloc affichée à côté — c'est elle qui aide à
    /// choisir quel objectif va où.
    private func champ(pour position: Int) -> some View {
        let couleur = PaletteBlocs.couleur(pour: position, sombre: theme == .dark)

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                RoundedRectangle(cornerRadius: 6)
                    .fill(couleur)
                    .frame(width: 18, height: 18)
                Text("\(Int(reglages.duree(pour: position)) / 60) minutes")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            TextField("Que veux-tu faire ?", text: $titres[position], axis: .vertical)
                .font(.title3)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.next)
                .focused($champActif, equals: position)
                .padding(.vertical, 12)
                .padding(.horizontal, 14)
                .background(couleur.opacity(theme == .dark ? 0.22 : 0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))
        }
    }

    private func champSuivant() {
        guard let actif = champActif else { return }
        let suivant = actif + 1
        champActif = suivant < Clepsydre.nombreDeBlocs ? suivant : nil
    }

    private func enregistrer() {
        for objectif in objectifs where titres.indices.contains(objectif.position) {
            let titre = titres[objectif.position].trimmingCharacters(in: .whitespacesAndNewlines)
            if objectif.titre != titre { objectif.titre = titre }
        }
    }
}
