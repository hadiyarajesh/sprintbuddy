import Foundation

@main struct Tests {
    static func main() {
        // legacy `note` migrates to updates; missing fields default
        let json = """
        {"id":"s1","name":"S","start":"2026-07-01","weeks":2,
         "days":{"2026-07-01":{"status":"working","note":"line a\\nline b"},
                 "2026-07-02":{"status":"leave"}}}
        """.data(using: .utf8)!
        let s = try! JSONDecoder().decode(SprintDTO.self, from: json)
        t.expectEqual(s.description, "", "missing description defaults empty")
        t.expectEqual(s.days["2026-07-01"]!.updates.count, 2, "legacy note -> 2 updates")
        t.expectEqual(s.days["2026-07-01"]!.updates[0].type, .done, "migrated update is done")
        t.expectEqual(s.days["2026-07-01"]!.updates[1].text, "line b", "second migrated line")
        t.expectEqual(s.days["2026-07-02"]!.privateNote, "", "missing privateNote defaults empty")
        t.expectEqual(s.orderedDates, ["2026-07-01","2026-07-02"], "ordered dates")
        t.summary()
    }
}
