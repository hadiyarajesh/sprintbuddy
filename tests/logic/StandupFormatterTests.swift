import Foundation

@main struct Tests {
    static func main() {
        var days = SprintMath.generateDays(start: "2026-07-01", weeks: 1)
        days["2026-07-01"]!.updates = [UpdateDTO(id: "u", type: .done, text: "shipped")]
        days["2026-07-02"]!.status = .leave
        let s = SprintDTO(id: "s", name: "Sprint 24.14", description: "APIs", start: "2026-07-01", weeks: 1, days: days)
        let out = StandupFormatter.text(s)
        t.expect(out.hasPrefix("Sprint 24.14 — Jul 1 – Jul 7, 2026"), "header line")
        t.expect(out.contains("Focus: APIs"), "focus line")
        t.expect(out.contains("Wed, Jul 1"), "logged day label")
        t.expect(out.contains("  - [Done] shipped"), "bulleted update")
        t.expect(out.contains("Thu, Jul 2 — Leave"), "leave line")
        t.expectEqual(SprintMath.rangeShort(s), "Jul 1 – Jul 7", "range short")
        t.summary()
    }
}
