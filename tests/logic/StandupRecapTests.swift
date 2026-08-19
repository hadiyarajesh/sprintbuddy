import Foundation

@main struct Tests {
    static func main() {
        // Empty store -> no recap; title/body are the nudge.
        t.expect(StandupRecap.lastWorkingDay([], before: "2026-07-09") == nil, "empty -> nil")
        t.expectEqual(StandupRecap.notificationTitle(nil), "Time to log your standup", "nil title is nudge")
        t.expect(StandupRecap.notificationBody(nil).contains("recently"), "nil body is the generic nudge")

        var days = SprintMath.generateDays(start: "2026-07-06", weeks: 1)
        days["2026-07-06"]!.updates = [UpdateDTO(id: "a", type: .done, text: "older")]
        days["2026-07-08"]!.updates = [
            UpdateDTO(id: "b", type: .done, text: "shipped X"),
            UpdateDTO(id: "c", type: .blocker, text: "blocked on Y"),
        ]
        let s = SprintDTO(id: "s", name: "Sprint 1", start: "2026-07-06", weeks: 1, days: days)

        // Jul 9 is a working day with nothing logged: it is the last working day
        // before Jul 10, so it's reported (empty) rather than skipped.
        let jul9 = StandupRecap.lastWorkingDay([s], before: "2026-07-10")
        t.expectEqual(jul9!.dateISO, "2026-07-09", "last working day is Jul 9")
        t.expect(jul9!.updates.isEmpty, "Jul 9 has nothing logged")
        t.expectEqual(StandupRecap.notificationTitle(jul9), "Time to log your standup", "empty day -> nudge title")
        t.expect(StandupRecap.notificationBody(jul9).contains("Jul 9"), "empty-day body names the day")

        // Today itself is never recapped, even when logged.
        let beforeJul9 = StandupRecap.lastWorkingDay([s], before: "2026-07-09")
        t.expectEqual(beforeJul9!.dateISO, "2026-07-08", "strictly before today")
        t.expectEqual(beforeJul9!.updates.count, 2, "carries that day's updates")
        t.expectEqual(beforeJul9!.sprintName, "Sprint 1", "carries sprint name")

        let body = StandupRecap.notificationBody(beforeJul9)
        t.expect(body.contains("[Done] shipped X"), "body lists done update")
        t.expect(body.contains("[Blocker] blocked on Y"), "body lists blocker update")
        t.expect(StandupRecap.notificationTitle(beforeJul9).contains("Jul 8"), "title names the day")

        // Real-world shape (Aug 2026): Thu 13 worked, Fri 14 holiday, Sat/Sun
        // weekend. Monday's recap must reach back past all three to Thursday.
        var aug = SprintMath.generateDays(start: "2026-08-10", weeks: 2)
        aug["2026-08-13"]!.updates = [UpdateDTO(id: "d", type: .done, text: "thursday work")]
        aug["2026-08-14"]!.status = .holiday
        let augSprint = SprintDTO(id: "s3", name: "Aug", start: "2026-08-10", weeks: 2, days: aug)
        let monday = StandupRecap.lastWorkingDay([augSprint], before: "2026-08-17")
        t.expectEqual(monday!.dateISO, "2026-08-13", "skips holiday + weekend back to Thursday")
        t.expectEqual(monday!.updates.count, 1, "carries Thursday's update")

        // A weekend day that WAS logged still counts as the last working day.
        var weekendWorked = aug
        weekendWorked["2026-08-15"]!.updates = [UpdateDTO(id: "e", type: .doing, text: "saturday work")]
        let sat = SprintDTO(id: "s4", name: "Aug", start: "2026-08-10", weeks: 2, days: weekendWorked)
        t.expectEqual(StandupRecap.lastWorkingDay([sat], before: "2026-08-17")!.dateISO,
                      "2026-08-15", "a logged Saturday beats the previous Thursday")

        // Leave with nothing logged is skipped like a holiday.
        var onLeave = aug
        onLeave["2026-08-13"]!.status = .leave
        onLeave["2026-08-13"]!.updates = []
        let leaveSprint = SprintDTO(id: "s5", name: "Aug", start: "2026-08-10", weeks: 2, days: onLeave)
        t.expectEqual(StandupRecap.lastWorkingDay([leaveSprint], before: "2026-08-17")!.dateISO,
                      "2026-08-12", "skips unlogged leave")

        // Updates merge across sprints covering the same day.
        var days2 = SprintMath.generateDays(start: "2026-07-06", weeks: 1)
        days2["2026-07-08"]!.updates = [UpdateDTO(id: "f", type: .doing, text: "other sprint work")]
        let s2 = SprintDTO(id: "s2", name: "Sprint 2", start: "2026-07-06", weeks: 1, days: days2)
        let merged = StandupRecap.lastWorkingDay([s, s2], before: "2026-07-09")
        t.expectEqual(merged!.updates.count, 3, "merges updates across sprints")
        t.expectEqual(merged!.sprintName, "Sprint 1", "named after first contributing sprint")

        t.summary()
    }
}
