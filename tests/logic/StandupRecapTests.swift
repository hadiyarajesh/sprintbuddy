import Foundation

@main struct Tests {
    static func main() {
        // Empty store -> no recap; body is the nudge.
        t.expect(StandupRecap.mostRecentLogged([], onOrBefore: "2026-07-09") == nil, "empty -> nil")
        t.expect(StandupRecap.notificationBody(nil).contains("don\u{2019}t forget"), "nil body is nudge")
        t.expect(StandupRecap.notificationTitle(nil) == "Time to log your standup", "nil title is nudge")

        var days = SprintMath.generateDays(start: "2026-07-06", weeks: 1)
        days["2026-07-06"]!.updates = [UpdateDTO(id: "a", type: .done, text: "older")]
        days["2026-07-08"]!.updates = [
            UpdateDTO(id: "b", type: .done, text: "shipped X"),
            UpdateDTO(id: "c", type: .blocker, text: "blocked on Y"),
        ]
        // A future day (after the cutoff) must be ignored.
        days["2026-07-10"]!.updates = [UpdateDTO(id: "d", type: .doing, text: "future")]
        let s = SprintDTO(id: "s", name: "Sprint 1", start: "2026-07-06", weeks: 1, days: days)

        let recap = StandupRecap.mostRecentLogged([s], onOrBefore: "2026-07-09")
        t.expect(recap != nil, "recap found")
        t.expectEqual(recap!.dateISO, "2026-07-08", "most recent logged before cutoff is Jul 8 (Jul 10 excluded)")
        t.expectEqual(recap!.updates.count, 2, "carries both updates")
        t.expectEqual(recap!.sprintName, "Sprint 1", "carries sprint name")

        let body = StandupRecap.notificationBody(recap)
        t.expect(body.contains("[Done] shipped X"), "body lists done update")
        t.expect(body.contains("[Blocker] blocked on Y"), "body lists blocker update")
        t.expect(StandupRecap.notificationTitle(recap).contains("Jul 8"), "title names the day")

        // logged(on:) — exact-day recap used by the notification.
        t.expect(StandupRecap.logged(on: "2026-07-07", in: [s]) == nil, "no updates that day -> nil")
        t.expect(StandupRecap.logged(on: "2026-07-08", in: []) == nil, "no sprints -> nil")
        let day8 = StandupRecap.logged(on: "2026-07-08", in: [s])
        t.expect(day8 != nil, "exact-day recap found")
        t.expectEqual(day8!.dateISO, "2026-07-08", "exact-day recap is for the asked day")
        t.expectEqual(day8!.updates.count, 2, "exact-day recap carries that day's updates")

        // Updates merge across sprints covering the same day.
        var days2 = SprintMath.generateDays(start: "2026-07-06", weeks: 1)
        days2["2026-07-08"]!.updates = [UpdateDTO(id: "e", type: .doing, text: "other sprint work")]
        let s2 = SprintDTO(id: "s2", name: "Sprint 2", start: "2026-07-06", weeks: 1, days: days2)
        let merged = StandupRecap.logged(on: "2026-07-08", in: [s, s2])
        t.expectEqual(merged!.updates.count, 3, "merges updates across sprints")
        t.expectEqual(merged!.sprintName, "Sprint 1", "named after first contributing sprint")

        // Nothing-logged copy says "yesterday".
        t.expect(StandupRecap.notificationBody(nil).contains("Nothing was logged yesterday"), "nil body mentions yesterday")
        t.summary()
    }
}
