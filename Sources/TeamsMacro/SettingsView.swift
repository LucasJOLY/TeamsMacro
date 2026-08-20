import KeyboardShortcuts
import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView {
            generalTab
            scheduleTab
            shortcutsTab
        }
        .frame(width: 460, height: 480)
    }

    private var generalTab: some View {
        Form {
            Section("Comportement") {
                LabeledContent("Intervalle") {
                    HStack(spacing: 8) {
                        TextField(
                            "",
                            value: $appState.intervalSeconds,
                            format: .number.precision(.fractionLength(0...1))
                        )
                        .labelsHidden()
                        .frame(width: 72)
                        .multilineTextAlignment(.trailing)
                        Text("secondes")
                            .foregroundStyle(.secondary)
                    }
                }

                LabeledContent("Amplitude") {
                    HStack(spacing: 8) {
                        TextField("", value: $appState.deltaPixels, format: .number)
                            .labelsHidden()
                            .frame(width: 72)
                            .multilineTextAlignment(.trailing)
                        Text("pixels")
                            .foregroundStyle(.secondary)
                    }
                }

                Text("Un déplacement minime suffit pour Teams. 240 s (4 min) est un bon défaut.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Démarrage") {
                Toggle("Lancer au démarrage de la session", isOn: launchAtLoginBinding)

                if let message = appState.launchAtLoginMessage {
                    Text(message)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }

                Button("Ouvrir les éléments de connexion…") {
                    LaunchAtLogin.openLoginItemsSettings()
                }
            }

            Section("Accessibilité") {
                LabeledContent("Autorisation") {
                    Text(appState.isTrusted ? "Accordée" : "Manquante")
                        .foregroundStyle(appState.isTrusted ? .green : .orange)
                }

                Text(AccessibilityPermission.currentAppPath)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)

                if !appState.isTrusted {
                    Text("Après avoir coché l’app dans Accessibilité, il faut la relancer. S’il y a plusieurs « Teams Macro », supprime les anciennes entrées et ajoute uniquement celle de /Applications.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Button("Ouvrir Accessibilité…") {
                        appState.requestPermission()
                        AccessibilityPermission.openSystemSettings()
                    }
                    Button("Relancer l’app") {
                        AccessibilityPermission.relaunch()
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .tabItem {
            Label("Général", systemImage: "gearshape")
        }
    }

    private var scheduleTab: some View {
        Form {
            Section {
                Toggle("Activer la planification", isOn: $appState.schedule.isEnabled)
            } footer: {
                Text("Quand elle est active, Teams Macro s’allume et s’éteint tout seul selon l’heure et les jours.")
            }

            Section("Horaires") {
                DatePicker(
                    "Démarrer à",
                    selection: startTimeBinding,
                    displayedComponents: .hourAndMinute
                )
                .disabled(!appState.schedule.isEnabled)

                DatePicker(
                    "Arrêter à",
                    selection: stopTimeBinding,
                    displayedComponents: .hourAndMinute
                )
                .disabled(!appState.schedule.isEnabled)

                Text(appState.schedule.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section {
                Toggle("Pause midi", isOn: $appState.schedule.lunchBreakEnabled)
                    .disabled(!appState.schedule.isEnabled)

                DatePicker(
                    "Début pause",
                    selection: lunchStartBinding,
                    displayedComponents: .hourAndMinute
                )
                .disabled(!appState.schedule.isEnabled || !appState.schedule.lunchBreakEnabled)

                DatePicker(
                    "Fin pause",
                    selection: lunchEndBinding,
                    displayedComponents: .hourAndMinute
                )
                .disabled(!appState.schedule.isEnabled || !appState.schedule.lunchBreakEnabled)
            } header: {
                Text("Pause déjeuner")
            } footer: {
                Text("Pendant cette plage, Teams Macro s’arrête puis reprend automatiquement.")
            }

            Section {
                ForEach(WeekdayOption.ordered) { day in
                    Toggle(day.label, isOn: excludedBinding(for: day.id))
                        .disabled(!appState.schedule.isEnabled)
                }
            } header: {
                Text("Jours exclus")
            } footer: {
                Text("Les jours cochés sont ignorés (ex. week-end).")
            }
        }
        .formStyle(.grouped)
        .padding()
        .tabItem {
            Label("Planning", systemImage: "calendar")
        }
    }

    private var shortcutsTab: some View {
        Form {
            Section("Raccourcis globaux") {
                KeyboardShortcuts.Recorder("Activer", name: .activate)
                KeyboardShortcuts.Recorder("Désactiver", name: .deactivate)
                KeyboardShortcuts.Recorder("Basculer", name: .toggle)
            }

            Section {
                Button("Réinitialiser les raccourcis") {
                    KeyboardShortcuts.reset(.activate, .deactivate, .toggle)
                }
            } footer: {
                Text("Les raccourcis fonctionnent même quand une autre app est au premier plan. Défaut bascule : ⌃⌥⌘T.")
            }
        }
        .formStyle(.grouped)
        .padding()
        .tabItem {
            Label("Raccourcis", systemImage: "keyboard")
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { appState.launchAtLoginEnabled },
            set: { appState.setLaunchAtLogin($0) }
        )
    }

    private var startTimeBinding: Binding<Date> {
        Binding(
            get: { date(fromMinutes: appState.schedule.startMinutes) },
            set: { appState.schedule.startMinutes = minutes(from: $0) }
        )
    }

    private var stopTimeBinding: Binding<Date> {
        Binding(
            get: { date(fromMinutes: appState.schedule.stopMinutes) },
            set: { appState.schedule.stopMinutes = minutes(from: $0) }
        )
    }

    private var lunchStartBinding: Binding<Date> {
        Binding(
            get: { date(fromMinutes: appState.schedule.lunchStartMinutes) },
            set: { appState.schedule.lunchStartMinutes = minutes(from: $0) }
        )
    }

    private var lunchEndBinding: Binding<Date> {
        Binding(
            get: { date(fromMinutes: appState.schedule.lunchEndMinutes) },
            set: { appState.schedule.lunchEndMinutes = minutes(from: $0) }
        )
    }

    private func excludedBinding(for weekday: Int) -> Binding<Bool> {
        Binding(
            get: { appState.schedule.excludedWeekdays.contains(weekday) },
            set: { appState.setWeekdayExcluded(weekday, excluded: $0) }
        )
    }

    private func date(fromMinutes value: Int) -> Date {
        Calendar.current.date(
            bySettingHour: value / 60,
            minute: value % 60,
            second: 0,
            of: Date()
        ) ?? Date()
    }

    private func minutes(from date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
