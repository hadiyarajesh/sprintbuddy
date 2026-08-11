import Foundation

@main struct Tests {
    static func main() {
        let days = SprintMath.generateDays(start: "2026-07-01", weeks: 2)
        t.expectEqual(days.count, 14, "14 days generated")
        t.expectEqual(days["2026-07-04"]!.status, .weekend, "Sat is weekend")   // 2026-07-04 is Sat
        t.expectEqual(days["2026-07-01"]!.status, .working, "Wed is working")

        let sixDayWeek = SprintMath.generateDays(start: "2026-07-01", weeks: 1, saturdayIsWorkingDay: true)
        t.expectEqual(sixDayWeek["2026-07-04"]!.status, .working, "Sat is working when enabled")
        let weekdaysOnly = SprintMath.visibleDates(
            SprintDTO(id: "six-day", name: "n", start: "2026-07-01", weeks: 1, days: sixDayWeek),
            showWeekends: false
        )
        t.expect(weekdaysOnly.contains("2026-07-04"), "working Saturday remains visible when weekends are hidden")

        var s = SprintDTO(id: "s", name: "n", start: "2026-07-01", weeks: 2, days: days)
        s.days["2026-07-01"]!.updates = [UpdateDTO(id: "u1", type: .done, text: "x")]
        s.days["2026-07-03"]!.status = .holiday
        s.days["2026-07-02"]!.status = .leave
        let st = SprintMath.stats(s)
        t.expectEqual(st.leave, 1, "1 leave")
        t.expectEqual(st.holiday, 1, "1 holiday")
        t.expectEqual(st.logged, 1, "1 logged")
        t.expect(st.working >= 8, "working excludes weekend/leave/holiday")
        t.expectEqual(SprintMath.status(s, today: "2026-07-05"), .active, "spans today -> active")
        t.expectEqual(SprintMath.status(s, today: "2026-07-30"), .completed, "past -> completed")
        t.expectEqual(SprintMath.status(s, today: "2026-06-01"), .upcoming, "future -> upcoming")
        t.expectEqual(SprintMath.dayIndex(s, today: "2026-07-05"), 5, "day 5 of 14")
        t.expectEqual(SprintMath.defaultDate(s, today: "2026-07-05"), "2026-07-05", "today is default")
        t.summary()
    }
}
