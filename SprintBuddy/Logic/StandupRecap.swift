//
//  StandupRecap.swift
//  SprintBuddy
//
//  Pure logic for the daily recap: finds the most recent logged day across all
//  sprints and formats notification title/body text. Foundation-only so it can
//  be unit-tested with `swiftc` (see tests/logic/StandupRecapTests.swift).
//

import Foundation

enum StandupRecap {
    struct DayRecap: Equatable {
        let dateISO: String
        let sprintName: String
        let updates: [UpdateDTO]
    }

    /// The most recent day (by ISO date, on or before `todayISO`) across all
    /// sprints that has at least one update. `nil` when nothing has been logged.
    static func mostRecentLogged(_ sprints: [SprintDTO], onOrBefore todayISO: String) -> DayRecap? {
        var best: DayRecap?
        for sprint in sprints {
            for (iso, day) in sprint.days where iso <= todayISO && !day.updates.isEmpty {
                if best == nil || iso > best!.dateISO {
                    best = DayRecap(dateISO: iso, sprintName: sprint.name, updates: day.updates)
                }
            }
        }
        return best
    }

    private static let typeLabel: [UpdateType: String] = [.done: "Done", .doing: "Doing", .blocker: "Blocker"]

    /// Notification title — names the recapped day, or nudges when there's nothing.
    static func notificationTitle(_ recap: DayRecap?) -> String {
        guard let recap else { return "Time to log your standup" }
        return "Standup recap \u{2014} \(SprintMath.fmtShort(DateKey.parse(recap.dateISO)))"
    }

    /// Notification body — a short bulleted recap, or a nudge when there's nothing.
    static func notificationBody(_ recap: DayRecap?, maxItems: Int = 4) -> String {
        guard let recap else {
            return "No updates logged recently \u{2014} don\u{2019}t forget to log today."
        }
        var lines = recap.updates.prefix(maxItems).map { "\u{2022} [\(typeLabel[$0.type] ?? "")] \($0.text)" }
        if recap.updates.count > maxItems {
            lines.append("+\(recap.updates.count - maxItems) more")
        }
        return lines.joined(separator: "\n")
    }
}
