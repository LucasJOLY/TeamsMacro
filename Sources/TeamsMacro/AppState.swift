import AppKit
import Combine
import Foundation
import KeyboardShortcuts
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var intervalSeconds: Double {
        didSet {
            UserDefaults.standard.set(intervalSeconds, forKey: Keys.interval)
            restartLoopIfNeeded()
        }
    }

    @Published var deltaPixels: Int {
        didSet {
            UserDefaults.standard.set(deltaPixels, forKey: Keys.delta)
        }
    }

    @Published var schedule: ScheduleConfiguration {
        didSet {
            ScheduleStorage.save(schedule)
            syncSchedule()
        }
    }

    @Published var launchAtLoginEnabled: Bool = false
    @Published var launchAtLoginMessage: String?

    @Published private(set) var isEnabled = false
    @Published private(set) var isTrusted = AccessibilityPermission.isGranted
    @Published private(set) var lastJiggleAt: Date?
    @Published private(set) var scheduleWantsActive = false

    private var loopTask: Task<Void, Never>?
    private var permissionTimer: AnyCancellable?
    private var scheduleTimer: AnyCancellable?
    private var activationObserver: AnyCancellable?
    private var shortcutTasks: [Task<Void, Never>] = []

    private enum Keys {
        static let interval = "intervalSeconds"
        static let delta = "deltaPixels"
        static let didConfigureLaunchAtLogin = "didConfigureLaunchAtLogin"
    }

    init() {
        let defaults = UserDefaults.standard
        intervalSeconds = defaults.object(forKey: Keys.interval) as? Double ?? 240
        deltaPixels = defaults.object(forKey: Keys.delta) as? Int ?? 1
        schedule = ScheduleStorage.load()
        launchAtLoginEnabled = LaunchAtLogin.isEnabled

        observeShortcuts()
        observeAppActivation()
        permissionTimer = Timer.publish(every: 2, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshPermission()
                self?.refreshLaunchAtLoginStatus()
            }

        scheduleTimer = Timer.publish(every: 15, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.syncSchedule()
            }

        configureLaunchAtLoginOnFirstRunIfNeeded()
        syncSchedule()
    }

    var statusLine: String {
        if !isTrusted { return "Autorisation Accessibilité manquante" }
        if isEnabled { return "Actif" }
        if schedule.isEnabled {
            if schedule.isWithinLunchBreak() {
                return "Pause midi"
            }
            return scheduleWantsActive ? "En attente (planifié)" : "Inactif (hors créneau)"
        }
        return "Inactif"
    }

    func activate(interactive: Bool = true) {
        if interactive {
            guard ensurePermission() else { return }
        } else {
            refreshPermission()
            guard isTrusted else { return }
        }
        isEnabled = true
        startLoop()
    }

    func deactivate() {
        isEnabled = false
        stopLoop()
    }

    func toggle() {
        if isEnabled {
            deactivate()
        } else {
            activate()
        }
    }

    func refreshPermission() {
        isTrusted = AccessibilityPermission.isGranted
        if !isTrusted, isEnabled {
            deactivate()
        }
    }

    func requestPermission() {
        AccessibilityPermission.request()
        refreshPermission()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            let status = try LaunchAtLogin.setEnabled(enabled)
            launchAtLoginEnabled = status == .enabled
            switch status {
            case .enabled:
                launchAtLoginMessage = nil
            case .requiresApproval:
                launchAtLoginMessage = "Autorise Teams Macro dans Ouverture et éléments de connexion."
                LaunchAtLogin.openLoginItemsSettings()
            case .notFound:
                launchAtLoginMessage = "Installe l’app dans /Applications (make install), puis réessaie."
                launchAtLoginEnabled = false
            case .notRegistered:
                launchAtLoginMessage = enabled ? "Enregistrement impossible." : nil
                launchAtLoginEnabled = false
            @unknown default:
                launchAtLoginMessage = "État de démarrage inconnu."
            }
        } catch {
            launchAtLoginEnabled = LaunchAtLogin.isEnabled
            launchAtLoginMessage = error.localizedDescription
        }
    }

    func refreshLaunchAtLoginStatus() {
        let enabled = LaunchAtLogin.isEnabled
        if launchAtLoginEnabled != enabled {
            launchAtLoginEnabled = enabled
        }
        if LaunchAtLogin.needsApproval {
            launchAtLoginMessage = "Autorise Teams Macro dans Ouverture et éléments de connexion."
        }
    }

    func syncSchedule() {
        scheduleWantsActive = schedule.shouldBeActive()
        guard schedule.isEnabled else { return }

        if scheduleWantsActive, !isEnabled {
            activate(interactive: false)
        } else if !scheduleWantsActive, isEnabled {
            deactivate()
        }
    }

    func setWeekdayExcluded(_ weekday: Int, excluded: Bool) {
        var next = schedule
        if excluded {
            next.excludedWeekdays.insert(weekday)
        } else {
            next.excludedWeekdays.remove(weekday)
        }
        schedule = next
    }

    private func configureLaunchAtLoginOnFirstRunIfNeeded() {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: Keys.didConfigureLaunchAtLogin) == nil else { return }
        defaults.set(true, forKey: Keys.didConfigureLaunchAtLogin)
        setLaunchAtLogin(true)
    }

    private func ensurePermission() -> Bool {
        refreshPermission()
        if isTrusted { return true }
        AccessibilityPermission.request()
        refreshPermission()
        return isTrusted
    }

    private func observeShortcuts() {
        shortcutTasks = [
            Task { [weak self] in
                for await event in KeyboardShortcuts.events(for: .activate) where event == .keyUp {
                    self?.activate()
                }
            },
            Task { [weak self] in
                for await event in KeyboardShortcuts.events(for: .deactivate) where event == .keyUp {
                    self?.deactivate()
                }
            },
            Task { [weak self] in
                for await event in KeyboardShortcuts.events(for: .toggle) where event == .keyUp {
                    self?.toggle()
                }
            }
        ]
    }

    private func observeAppActivation() {
        activationObserver = NotificationCenter.default.publisher(
            for: NSApplication.didBecomeActiveNotification
        )
        .sink { [weak self] _ in
            self?.refreshPermission()
            if self?.isTrusted == true {
                self?.syncSchedule()
            }
        }
    }

    private func restartLoopIfNeeded() {
        guard isEnabled else { return }
        startLoop()
    }

    private func startLoop() {
        stopLoop()
        let interval = max(intervalSeconds, 5)
        let delta = max(deltaPixels, 1)
        loopTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self, self.isEnabled else { break }
                if AccessibilityPermission.isGranted {
                    MouseJiggler.jiggle(by: delta)
                    self.lastJiggleAt = Date()
                } else {
                    self.refreshPermission()
                    self.deactivate()
                    break
                }
                let nanos = UInt64(interval * 1_000_000_000)
                try? await Task.sleep(nanoseconds: nanos)
            }
        }
    }

    private func stopLoop() {
        loopTask?.cancel()
        loopTask = nil
    }
}
