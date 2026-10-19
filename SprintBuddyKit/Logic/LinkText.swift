import Foundation

/// Finds web links in update text and shows them with short labels.
///
/// Only the display changes: the stored text keeps full URLs, so editing,
/// standup notes and exports are unaffected. A long link such as
/// `https://github.com/acme/app/pull/42` reads as `app/pull/42`; the full URL
/// is still what opens.
public enum LinkText {
    public enum Segment: Equatable {
        case text(String)
        case link(label: String, url: URL)
    }

    /// Links whose cleaned-up form fits in this many characters are shown whole.
    static let maxInlineLength = 40

    private static let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)

    public static func segments(in text: String) -> [Segment] {
        guard let detector else { return text.isEmpty ? [] : [.text(text)] }
        let ns = text as NSString
        var out: [Segment] = []
        var cursor = 0
        for match in detector.matches(in: text, range: NSRange(location: 0, length: ns.length)) {
            guard let url = match.url, ["http", "https"].contains(url.scheme?.lowercased() ?? "") else { continue }
            if match.range.location > cursor {
                out.append(.text(ns.substring(with: NSRange(location: cursor, length: match.range.location - cursor))))
            }
            out.append(.link(label: shortLabel(for: url), url: url))
            cursor = match.range.location + match.range.length
        }
        if cursor < ns.length { out.append(.text(ns.substring(from: cursor))) }
        return out
    }

    public static func linkCount(in text: String) -> Int {
        segments(in: text).filter { if case .link = $0 { return true }; return false }.count
    }

    /// The URL without scheme, `www.`, query or fragment; if that's still
    /// long, just its last three path components.
    public static func shortLabel(for url: URL) -> String {
        var host = url.host ?? ""
        if host.hasPrefix("www.") { host.removeFirst(4) }
        let parts = url.path.split(separator: "/").map(String.init)
        let whole = ([host] + parts).joined(separator: "/")
        guard whole.count > maxInlineLength, parts.count >= 3 else { return whole }
        return parts.suffix(3).joined(separator: "/")
    }

    /// Text ready for display. With `linked`, links are clickable; without
    /// (e.g. small previews that are themselves click targets), only the
    /// short labels are applied.
    public static func attributed(_ text: String, linked: Bool = true) -> AttributedString {
        var out = AttributedString()
        for segment in segments(in: text) {
            switch segment {
            case .text(let s):
                out += AttributedString(s)
            case .link(let label, let url):
                var piece = AttributedString(label)
                if linked { piece.link = url }
                out += piece
            }
        }
        return out
    }
}
