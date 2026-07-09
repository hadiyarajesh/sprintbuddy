import Foundation

@main struct Tests {
    static func main() {
        let sprint = SprintDTO(id: "s1", name: "S", description: "d", start: "2026-07-01", weeks: 1,
                               days: SprintMath.generateDays(start: "2026-07-01", weeks: 1))
        let data = ScrumBuddyCodec.encode([sprint])
        let str = String(data: data, encoding: .utf8)!
        t.expect(str.contains("\"app\" : \"ScrumBuddy\""), "app field present")
        t.expect(str.contains("\"schema\" : 5"), "schema 5")

        if case .success(let back) = ScrumBuddyCodec.decode(data) {
            t.expectEqual(back.count, 1, "round-trip 1 sprint")
            t.expectEqual(back[0].days.count, 7, "round-trip 7 days")
        } else { t.expect(false, "valid data should decode") }

        if case .failure(let e) = ScrumBuddyCodec.decode("not json".data(using: .utf8)!) {
            t.expectEqual(e, .notJSON, "garbage -> notJSON")
        } else { t.expect(false, "garbage should fail") }

        if case .failure(let e) = ScrumBuddyCodec.decode("{\"sprints\":[]}".data(using: .utf8)!) {
            t.expectEqual(e, .notScrumBuddy, "empty sprints -> notScrumBuddy")
        } else { t.expect(false, "empty sprints should fail") }
        t.summary()
    }
}
