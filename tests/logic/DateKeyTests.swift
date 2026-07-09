import Foundation

@main
struct Tests {
    static func main() {
        let d = DateKey.parse("2026-07-01")
        t.expectEqual(DateKey.iso(d), "2026-07-01", "round-trip iso")
        t.expectEqual(DateKey.iso(DateKey.addDays(d, 13)), "2026-07-14", "addDays 13")
        t.expectEqual(DateKey.daysBetween(DateKey.parse("2026-07-01"), DateKey.parse("2026-07-09")), 8, "daysBetween")
        t.expectEqual(DateKey.iso(DateKey.addDays(DateKey.parse("2026-03-08"), 1)), "2026-03-09", "DST spring-forward day")
        t.summary()
    }
}
