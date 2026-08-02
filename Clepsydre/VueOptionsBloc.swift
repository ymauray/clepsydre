import ClepsydreCore
import SwiftUI

/// L'appui long sur un bloc : renommer son objectif, rien d'autre.
///
/// La durée se règle dans l'écran de réglages, où elle a sa place — elle est globale, pas
/// propre à ce bloc-ci (SPECS §9). Et il n'y a pas de réinitialisation (SPECS §3).
struct VueOptionsBloc: View {
    @Environment(\.dismiss) private var fermer

    let bloc: Bloc
    let objectif: Objectif?
    let store: ReglagesStore

    @State private var titre: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Que veux-tu faire ?", text: $titre, axis: .vertical)
                } header: {
                    Text("Objectif")
                } footer: {
                    Text("La durée de ce bloc se règle dans les réglages : elle vaut pour tous les jours.")
                }

            }
            .navigationTitle("Bloc \(bloc.position + 1)")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") {
                        enregistrer()
                        fermer()
                    }
                }
            }
        }
        .onAppear {
            titre = objectif?.titre ?? ""
        }
    }

    private func enregistrer() {
        objectif?.titre = titre.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
