import Foundation

struct ScheduleConfiguration: Equatable {
    var isEnabled: Bool
    /// Minutes from midnight.
    var startMinutes: Int
    /// Minutes from midnight. Active window is [start, stop).
    var stopMinutes: Int
    var lunchBreakEnabled: Bool
    /// Pause midi : inactive dans [lunchStart, lunchEnd).
    var lunchStartMinutes: Int
    var lunchEndMinutes: Int
    /// Calendar weekdays to skip (1 = dimanche … 7 = samedi).
    var excludedWeekdays: Set<Int>

    static let `default` = ScheduleConfiguration(
        isEnabled: true,
        startMinutes: 9 * 60,
        stopMinutes: 18 * 60,
        lunchBreakEnabled: true,
        lunchStartMinutes: 12 * 60,
        lunchEndMinutes: 13 * 60 + 30,
        excludedWeekdays: [1, 7] // dimanche, samedi
    )

    func shouldBeActive(at date: Date = .now, calendar: Calendar = .current) -> Bool {
        guard isEnabled else { return false }

        let weekday = calendar.component(.weekday, from: date)
        if excludedWeekdays.contains(weekday) {
            return false
        }

        let minutes =
            calendar.component(.hour, from: date) * 60
            + calendar.component(.minute, from: date)

        guard isWithinWorkWindow(minutes) else { return false }
        if isWithinLunchBreak(minutes) { return false }
        return true
    }

    func isWithinLunchBreak(at date: Date = .now, calendar: Calendar = .current) -> Bool {
        guard isEnabled, lunchBreakEnabled else { return false }
        let minutes =
            calendar.component(.hour, from: date) * 60
            + calendar.component(.minute, from: date)
        return isWithinLunchBreak(minutes)
    }

    var summary: String {
        guard isEnabled else { return "Planification désactivée" }
        let start = Self.format(minutes: startMinutes)
        let stop = Self.format(minutes: stopMinutes)
        let days = WeekdayOption.ordered
            .filter { !excludedWeekdays.contains($0.id) }
            .map(\.shortLabel)
        let daysText = days.isEmpty ? "aucun jour" : days.joined(separator: ", ")

        var text = "\(start) → \(stop)"
        if lunchBreakEnabled {
            let lunchStart = Self.format(minutes: lunchStartMinutes)
            let lunchEnd = Self.format(minutes: lunchEndMinutes)
            text += " · pause \(lunchStart)–\(lunchEnd)"
        }
        text += " · \(daysText)"
        return text
    }

    static func format(minutes: Int) -> String {
        let clamped = max(0, min(minutes, 24 * 60 - 1))
        return String(format: "%02d:%02d", clamped / 60, clamped % 60)
    }

    private func isWithinWorkWindow(_ minutes: Int) -> Bool {
        if startMinutes == stopMinutes {
            return true
        }
        if startMinutes < stopMinutes {
            return minutes >= startMinutes && minutes < stopMinutes
        }
        // Fenêtre qui passe minuit (ex. 22:00 → 08:00).
        return minutes >= startMinutes || minutes < stopMinutes
    }

    private func isWithinLunchBreak(_ minutes: Int) -> Bool {
        guard lunchBreakEnabled else { return false }
        if lunchStartMinutes == lunchEndMinutes {
            return false
        }
        if lunchStartMinutes < lunchEndMinutes {
            return minutes >= lunchStartMinutes && minutes < lunchEndMinutes
        }
        return minutes >= lunchStartMinutes || minutes < lunchEndMinutes
    }
}

struct WeekdayOption: Identifiable, Hashable {
    let id: Int
    let label: String
    let shortLabel: String

    /// Ordre français : lundi → dimanche.
    static let ordered: [WeekdayOption] = [
        .init(id: 2, label: "Lundi", shortLabel: "lun."),
        .init(id: 3, label: "Mardi", shortLabel: "mar."),
        .init(id: 4, label: "Mercredi", shortLabel: "mer."),
        .init(id: 5, label: "Jeudi", shortLabel: "jeu."),
        .init(id: 6, label: "Vendredi", shortLabel: "ven."),
        .init(id: 7, label: "Samedi", shortLabel: "sam."),
        .init(id: 1, label: "Dimanche", shortLabel: "dim.")
    ]
}

enum ScheduleStorage {
    private enum Keys {
        static let enabled = "schedule.enabled"
        static let start = "schedule.startMinutes"
        static let stop = "schedule.stopMinutes"
        static let lunchEnabled = "schedule.lunchBreakEnabled"
        static let lunchStart = "schedule.lunchStartMinutes"
        static let lunchEnd = "schedule.lunchEndMinutes"
        static let excluded = "schedule.excludedWeekdays"
    }

    static func load() -> ScheduleConfiguration {
        let defaults = UserDefaults.standard
        guard defaults.object(forKey: Keys.enabled) != nil else {
            return .default
        }

        let excluded = Set(defaults.array(forKey: Keys.excluded) as? [Int] ?? [])
        let lunchEnabled = defaults.object(forKey: Keys.lunchEnabled) as? Bool
            ?? ScheduleConfiguration.default.lunchBreakEnabled

        return ScheduleConfiguration(
            isEnabled: defaults.bool(forKey: Keys.enabled),
            startMinutes: defaults.object(forKey: Keys.start) as? Int ?? ScheduleConfiguration.default.startMinutes,
            stopMinutes: defaults.object(forKey: Keys.stop) as? Int ?? ScheduleConfiguration.default.stopMinutes,
            lunchBreakEnabled: lunchEnabled,
            lunchStartMinutes: defaults.object(forKey: Keys.lunchStart) as? Int
                ?? ScheduleConfiguration.default.lunchStartMinutes,
            lunchEndMinutes: defaults.object(forKey: Keys.lunchEnd) as? Int
                ?? ScheduleConfiguration.default.lunchEndMinutes,
            excludedWeekdays: excluded
        )
    }

    static func save(_ schedule: ScheduleConfiguration) {
        let defaults = UserDefaults.standard
        defaults.set(schedule.isEnabled, forKey: Keys.enabled)
        defaults.set(schedule.startMinutes, forKey: Keys.start)
        defaults.set(schedule.stopMinutes, forKey: Keys.stop)
        defaults.set(schedule.lunchBreakEnabled, forKey: Keys.lunchEnabled)
        defaults.set(schedule.lunchStartMinutes, forKey: Keys.lunchStart)
        defaults.set(schedule.lunchEndMinutes, forKey: Keys.lunchEnd)
        defaults.set(Array(schedule.excludedWeekdays).sorted(), forKey: Keys.excluded)
    }
}
