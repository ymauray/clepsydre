import ClepsydreCore
import SwiftUI
import UIKit

/// Les réglages : quatre durées, notifications, heure du rappel (SPECS §4).
struct VueReglages: View {
    @Environment(\.dismiss) private var fermer
    @Environment(\.colorScheme) private var theme

    let store: ReglagesStore
    let blocs: [Bloc]
    let autorisations: AutorisationNotifications
    /// Repose le rappel matinal après un changement d'heure ou d'activation.
    let appliquerLeRappel: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    ForEach(0..<Clepsydre.nombreDeBlocs, id: \.self, content: reglageDeDuree)
                } header: {
                    Text("Durées")
                } footer: {
                    Text("Les durées valent pour tous les jours. Un bloc déjà terminé garde la sienne jusqu'à demain.")
                }

                Section {
                    Toggle("À la fin d'un bloc", isOn: liaison(\.notificationsDeFinActivees))
                    Toggle("Le matin", isOn: liaison(\.rappelMatinalActive))

                    if store.reglages.rappelMatinalActive {
                        DatePicker(
                            "Heure du rappel",
                            selection: heureDuRappel,
                            displayedComponents: .hourAndMinute
                        )
                    }
                } header: {
                    Text("Notifications")
                } footer: {
                    // Un constat, pas un reproche (SPECS §5.5).
                    if autorisations.refusee {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Les notifications sont désactivées pour Clepsydre dans les réglages de l'iPhone. L'app fonctionne sans.")
                            Button("Ouvrir les réglages de l'iPhone") {
                                guard let lien = URL(string: UIApplication.openSettingsURLString)
                                else { return }
                                UIApplication.shared.open(lien)
                            }
                        }
                    }
                }


                Section {
                    NavigationLink {
                        VueAide()
                    } label: {
                        Label("Comment ça marche", systemImage: "questionmark.circle")
                    }
                }
            }
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("OK") { fermer() }
                }
            }
        }
        .onChange(of: store.reglages.rappelMatinalActive) { _, _ in appliquerLeRappel() }
        .onChange(of: store.reglages.heureDuRappel) { _, _ in appliquerLeRappel() }
    }

    private func reglageDeDuree(_ position: Int) -> some View {
        let minutes = Int(store.reglages.duree(pour: position)) / 60

        return Stepper {
            HStack(spacing: 12) {
                RoundedRectangle(cornerRadius: 5)
                    .fill(PaletteBlocs.couleur(pour: position, sombre: theme == .dark))
                    .frame(width: 16, height: 16)
                Text(minutes == 1 ? "1 minute" : "\(minutes) minutes")
                    .monospacedDigit()
            }
        } onIncrement: {
            changerLaDuree(position, minutes: EchelleDesDurees.suivante(apres: minutes))
        } onDecrement: {
            changerLaDuree(position, minutes: EchelleDesDurees.precedente(avant: minutes))
        }
        .accessibilityLabel("Durée du bloc \(position + 1)")
    }

    private func changerLaDuree(_ position: Int, minutes: Int) {
        let duree = TimeInterval(minutes * 60)
        store.reglages.durees[position] = duree

        // La nouvelle durée s'applique aussi à aujourd'hui, sauf aux blocs déjà terminés :
        // on ne réécrit pas ce qui est fait (SPECS §3).
        guard let bloc = blocs.first(where: { $0.position == position }), bloc.etat != .termine
        else { return }
        bloc.duree = duree
    }

    private func liaison(_ chemin: WritableKeyPath<Reglages, Bool>) -> Binding<Bool> {
        Binding(
            get: { store.reglages[keyPath: chemin] },
            set: { store.reglages[keyPath: chemin] = $0 }
        )
    }

    /// `Reglages` conserve l'heure en composantes ; `DatePicker` veut une `Date`.
    private var heureDuRappel: Binding<Date> {
        Binding(
            get: {
                Calendar.current.date(from: store.reglages.heureDuRappel)
                    ?? Calendar.current.startOfDay(for: Date())
            },
            set: { nouvelle in
                store.reglages.heureDuRappel = Calendar.current.dateComponents(
                    [.hour, .minute], from: nouvelle
                )
            }
        )
    }
}
