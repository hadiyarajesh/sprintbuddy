import Foundation

public enum StandupFormatter {
    private static let typeLabel: [UpdateType: String] = [.done: "Done", .doing: "Doing", .blocker: "Blocker"]

    public static func text(_ s: SprintDTO) -> String {
        let st = SprintMath.stats(s)
        var lines: [String] = []
        lines.append("\(s.name) \u{2014} \(SprintMath.rangeLabel(s))")
        if !s.description.trimmingCharacters(in: .whitespaces).isEmpty {
            lines.append("Focus: \(s.description.trimmingCharacters(in: .whitespaces))")
        }
        lines.append("Logged \(st.logged) of \(st.working) working days \u{00b7} \(st.leave) leave \u{00b7} \(st.holiday) holiday")
        lines.append("")
        for iso in s.orderedDates {
            let day = s.days[iso]!
            let label = SprintMath.fmt(DateKey.parse(iso))
            switch day.status {
            case .leave: lines.append("\(label) \u{2014} Leave")
            case .holiday: lines.append("\(label) \u{2014} Holiday")
            case .weekend where day.updates.isEmpty: continue
            default:
                guard !day.updates.isEmpty else { continue }
                lines.append(label)
                for u in day.updates { lines.append("  - [\(typeLabel[u.type] ?? "Doing")] \(u.text)") }
            }
        }
        return lines.joined(separator: "\n")
    }
}
