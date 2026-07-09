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
        t.summary()
    }
}
