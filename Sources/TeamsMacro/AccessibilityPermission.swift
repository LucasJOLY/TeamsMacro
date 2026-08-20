import ApplicationServices
import AppKit

enum AccessibilityPermission {
    static var isGranted: Bool {
        AXIsProcessTrusted()
    }

    static var currentAppPath: String {
        Bundle.main.bundlePath
    }

    static var currentAppName: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String ?? "Teams Macro"
    }

    @discardableResult
    static func request() -> Bool {
        let options = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    static func openSystemSettings() {
        let candidates = [
            "x-apple.systempreferences:com.apple.settings.PrivacySecurity.extension?Privacy_Accessibility",
            "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        ]
        for candidate in candidates {
            if let url = URL(string: candidate), NSWorkspace.shared.open(url) {
                return
            }
        }
    }

    /// Relance obligatoire : TCC n’applique souvent l’Accessibilité qu’au prochain démarrage.
    static func relaunch() {
        let appURL = Bundle.main.bundleURL
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.createsNewApplicationInstance = true

        NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { _, error in
            DispatchQueue.main.async {
                if error != nil {
                    let process = Process()
                    process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
                    process.arguments = ["-n", appURL.path]
                    try? process.run()
                }
                NSApplication.shared.terminate(nil)
            }
        }
    }
}
