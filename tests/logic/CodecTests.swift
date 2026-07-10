import Foundation

@main struct Tests {
    static func main() {
        let sprint = SprintDTO(id: "s1", name: "S", description: "d", start: "2026-07-01", weeks: 1,
                               days: SprintMath.generateDays(start: "2026-07-01", weeks: 1))
        let data = try! SprintBuddyCodec.encode([sprint])
        let str = String(data: data, encoding: .utf8)!
        t.expect(str.contains("\"app\" : \"SprintBuddy\""), "app field present")
        t.expect(str.contains("\"schema\" : 5"), "schema 5")

        if case .success(let back) = SprintBuddyCodec.decode(data) {
            t.expectEqual(back.count, 1, "round-trip 1 sprint")
            t.expectEqual(back[0].days.count, 7, "round-trip 7 days")
        } else { t.expect(false, "valid data should decode") }

        if case .failure(let e) = SprintBuddyCodec.decode("not json".data(using: .utf8)!) {
            t.expectEqual(e, .notJSON, "garbage -> notJSON")
        } else { t.expect(false, "garbage should fail") }

        if case .failure(let e) = SprintBuddyCodec.decode("{\"sprints\":[]}".data(using: .utf8)!) {
            t.expectEqual(e, .notSprintBuddy, "empty sprints -> notSprintBuddy")
        } else { t.expect(false, "empty sprints should fail") }

        // Valid JSON of the wrong shape (an array) is "not SprintBuddy", not "not JSON".
        if case .failure(let e) = SprintBuddyCodec.decode("[1,2,3]".data(using: .utf8)!) {
            t.expectEqual(e, .notSprintBuddy, "valid non-object JSON -> notSprintBuddy")
        } else { t.expect(false, "array JSON should fail") }
        t.summary()
    }
}
