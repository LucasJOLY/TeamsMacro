import KeyboardShortcuts
import SwiftUI

struct MenuBarContent: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Text(appState.statusLine)

        if appState.schedule.isEnabled {
            Text(appState.schedule.summary)
        }

        if let last = appState.lastJiggleAt, appState.isTrusted {
            Text("Dernier mouvement : \(last.formatted(date: .omitted, time: .shortened))")
        }

        Divider()

        if !appState.isTrusted {
            Button("Ouvrir Accessibilité…") {
                appState.requestPermission()
                AccessibilityPermission.openSystemSettings()
            }

            Button("Relancer l’app") {
                AccessibilityPermission.relaunch()
            }

            Text("1. Coche « \(AccessibilityPermission.currentAppName) »")
            Text("2. Relance l’app (obligatoire)")
            Text(AccessibilityPermission.currentAppPath)
        }

        Button(appState.isEnabled ? "Désactiver" : "Activer") {
            appState.toggle()
        }
        .disabled(!appState.isTrusted && !appState.isEnabled)

        if let shortcut = KeyboardShortcuts.getShortcut(for: .toggle) {
            Text("Bascule : \(shortcut.description)")
        }

        Divider()

        Button("Réglages…") {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }
        .keyboardShortcut(",")

        Divider()

        Button("Quitter") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }
}
