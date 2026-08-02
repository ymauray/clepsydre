import ClepsydreCore
import SwiftUI

/// L'appui long : renommer l'objectif, ajuster la durée. Pas de réinitialisation (SPECS §3).
struct VueOptionsBloc: View {
    @Environment(\.dismiss) private var fermer

    let bloc: Bloc
    let objectif: Objectif?
    let store: ReglagesStore

    @State private var titre: String = ""
    @State private var minutes = 0

    var body: some View {
        NavigationStack {
            Form {
                Section("Objectif") {
                    TextField("Que veux-tu faire ?", text: $titre, axis: .vertical)
                }

                Section {
                    Stepper {
                        Text(minutes == 1 ? "1 minute" : "\(minutes) minutes")
                    } onIncrement: {
                        minutes = EchelleDesDurees.suivante(apres: minutes)
                    } onDecrement: {
                        minutes = EchelleDesDurees.precedente(avant: minutes)
                    }
                } header: {
                    Text("Durée")
                } footer: {
                    Text("La durée est globale : elle vaut aussi pour les jours suivants.")
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
            minutes = Int((store.reglages.duree(pour: bloc.position) / 60).rounded())
        }
    }

    private func enregistrer() {
        objectif?.titre = titre.trimmingCharacters(in: .whitespacesAndNewlines)

        let nouvelleDuree = TimeInterval(minutes * 60)
        guard nouvelleDuree != bloc.duree else { return }
        store.reglages.durees[bloc.position] = nouvelleDuree
        // Un bloc déjà terminé garde sa durée du jour : on ne le ramène pas en arrière.
        if bloc.etat != .termine { bloc.duree = nouvelleDuree }
    }
}
