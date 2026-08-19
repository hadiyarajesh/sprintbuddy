//
//  StandupRecap.swift
//  SprintBuddyKit
//
//  Pure logic for the daily recap: finds the last working day across all
//  sprints and formats notification title/body text. Foundation-only so it can
//  be unit-tested with `swiftc` (see tests/logic/StandupRecapTests.swift).
//

import Foundation

public enum StandupRecap {
    public struct DayRecap: Equatable {
        public let dateISO: String
        public let sprintName: String
        public let updates: [UpdateDTO]

        public init(dateISO: String, sprintName: String, updates: [UpdateDTO]) {
            self.dateISO = dateISO; self.sprintName = sprintName; self.updates = updates
        }
    }

    /// The last day worth recapping before `todayISO`: the most recent working
    /// day, plus any non-working day that was actually logged on (a Saturday
    /// you worked still counts). Weekends, holidays, and leave with nothing
    /// logged are skipped, so Monday's recap reaches back past the weekend to
    /// Friday rather than reporting an empty Sunday.
    ///
    /// Updates are merged across every sprint covering that day. Returns `nil`
    /// only when no such day exists; `updates` may be empty, meaning it *was* a
    /// working day but nothing was logged.
    public static func lastWorkingDay(_ sprints: [SprintDTO], before todayISO: String) -> DayRecap? {
        var byDate: [String: (name: String, updates: [UpdateDTO])] = [:]
        for sprint in sprints {
            for (iso, day) in sprint.days where iso < todayISO {
                guard day.status == .working || !day.updates.isEmpty else { continue }
                var entry = byDate[iso] ?? (name: sprint.name, updates: [])
                entry.updates.append(contentsOf: day.updates)
                byDate[iso] = entry
            }
        }
        guard let latest = byDate.keys.max(), let entry = byDate[latest] else { return nil }
        return DayRecap(dateISO: latest, sprintName: entry.name, updates: entry.updates)
    }

    private static let typeLabel: [UpdateType: String] = [.done: "Done", .doing: "Doing", .blocker: "Blocker"]

    /// Notification title — names the recapped day, or nudges when that day has
    /// nothing logged.
    public static func notificationTitle(_ recap: DayRecap?) -> String {
        guard let recap, !recap.updates.isEmpty else { return "Time to log your standup" }
        return "Standup recap \u{2014} \(SprintMath.fmtShort(DateKey.parse(recap.dateISO)))"
    }

    /// Notification body — a short bulleted recap, or a nudge naming the day
    /// that came up empty.
    public static func notificationBody(_ recap: DayRecap?, maxItems: Int = 4) -> String {
        guard let recap, !recap.updates.isEmpty else {
            let when = recap.map { " on \(SprintMath.fmtShort(DateKey.parse($0.dateISO)))" } ?? " recently"
            return "Nothing was logged\(when) \u{2014} don\u{2019}t forget to log today."
        }
        var lines = recap.updates.prefix(maxItems).map { "\u{2022} [\(typeLabel[$0.type] ?? "")] \($0.text)" }
        if recap.updates.count > maxItems {
            lines.append("+\(recap.updates.count - maxItems) more")
        }
        return lines.joined(separator: "\n")
    }
}
