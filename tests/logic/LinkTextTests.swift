import Foundation

@main struct Tests {
    static func main() {
        let pr = "https://github.com/personatech-infra/phoenix-flutter/pull/42"
        t.expectEqual(LinkText.shortLabel(for: URL(string: pr)!), "phoenix-flutter/pull/42", "long GitHub PR keeps last 3 path parts")
        t.expectEqual(LinkText.shortLabel(for: URL(string: "https://www.example.com/docs?x=1#top")!), "example.com/docs",
                      "short link drops scheme, www, query, fragment")
        t.expectEqual(LinkText.shortLabel(for: URL(string: "https://example.com")!), "example.com", "bare host")

        let segs = LinkText.segments(in: "Merge PR\n1. \(pr)\n2. https://example.com/a.")
        t.expectEqual(segs, [
            .text("Merge PR\n1. "),
            .link(label: "phoenix-flutter/pull/42", url: URL(string: pr)!),
            .text("\n2. "),
            .link(label: "example.com/a", url: URL(string: "https://example.com/a")!),
            .text("."),
        ], "splits text around links, trailing period stays text")
        t.expectEqual(LinkText.segments(in: "no links here"), [.text("no links here")], "plain text untouched")
        t.expectEqual(LinkText.segments(in: ""), [], "empty text")
        t.expect(!LinkText.segments(in: "mail me@example.com").contains { if case .link = $0 { return true }; return false },
                 "email addresses are not turned into links")

        t.expectEqual(LinkText.linkCount(in: "Merge PR\n1. \(pr)\n2. https://example.com/a."), 2, "counts every link")
        t.expectEqual(LinkText.linkCount(in: "no links, just me@example.com"), 0, "no links counts zero")

        let linked = LinkText.attributed("see \(pr)")
        t.expectEqual(String(linked.characters), "see phoenix-flutter/pull/42", "display text uses the short label")
        t.expectEqual(linked.runs.compactMap(\.link).first, URL(string: pr), "full URL is the link target")
        t.expect(LinkText.attributed("see \(pr)", linked: false).runs.allSatisfy { $0.link == nil }, "unlinked mode has no links")
        t.summary()
    }
}
