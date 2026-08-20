import SwiftUI

@main
struct TeamsMacroApp: App {
    @StateObject private var appState = AppState()
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarContent()
                .environmentObject(appState)
        } label: {
            MenuBarLabel(isEnabled: appState.isEnabled, isTrusted: appState.isTrusted)
        }

        Settings {
            SettingsView()
                .environmentObject(appState)
        }
    }
}

private struct MenuBarLabel: View {
    let isEnabled: Bool
    let isTrusted: Bool

    var body: some View {
        Image(systemName: iconName)
            .symbolRenderingMode(.hierarchical)
            .accessibilityLabel(accessibilityLabel)
    }

    private var iconName: String {
        if !isTrusted { return "exclamationmark.circle" }
        return isEnabled ? "circle.fill" : "circle"
    }

    private var accessibilityLabel: String {
        if !isTrusted { return "Teams Macro — autorisation requise" }
        return isEnabled ? "Teams Macro — actif" : "Teams Macro — inactif"
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
