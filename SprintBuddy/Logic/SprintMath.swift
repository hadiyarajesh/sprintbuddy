import Foundation

enum SprintMath {
    static func generateDays(start: String, weeks: Int) -> [String: DayDTO] {
        var out: [String: DayDTO] = [:]
        let s = DateKey.parse(start)
        for i in 0..<(weeks * 7) {
            let d = DateKey.addDays(s, i)
            out[DateKey.iso(d)] = DayDTO(status: DateKey.isWeekend(d) ? .weekend : .working)
        }
        return out
    }

    struct Stats: Equatable { var working = 0, logged = 0, leave = 0, holiday = 0 }

    static func stats(_ s: SprintDTO) -> Stats {
        var out = Stats()
        for (_, day) in s.days {
            switch day.status {
            case .working:
                out.working += 1
                if !day.updates.isEmpty { out.logged += 1 }
            case .leave: out.leave += 1
            case .holiday: out.holiday += 1
            case .weekend: break
            }
        }
        return out
    }

    static func progressPct(_ s: SprintDTO) -> Int {
        let st = stats(s)
        guard st.working > 0 else { return 0 }
        return Int((Double(st.logged) / Double(st.working) * 100).rounded())
    }

    enum SprintStatus: String { case active, completed, upcoming }

    static func status(_ s: SprintDTO, today: String) -> SprintStatus {
        let dates = s.orderedDates
        guard let end = dates.last else { return .upcoming }
        if end < today { return .completed }
        if s.start > today { return .upcoming }
        return .active
    }

    static func dayIndex(_ s: SprintDTO, today: String) -> Int? {
        guard status(s, today: today) == .active else { return nil }
        let total = s.weeks * 7
        var idx = DateKey.daysBetween(DateKey.parse(s.start), DateKey.parse(today)) + 1
        idx = max(1, min(total, idx))
        return idx
    }

    static func defaultDate(_ s: SprintDTO, today: String) -> String? {
        let dates = s.orderedDates
        guard !dates.isEmpty else { return nil }
        if s.days[today] != nil { return today }
        if let firstWork = dates.first(where: { s.days[$0]?.status != .weekend }) { return firstWork }
        return dates.first
    }

    static func visibleDates(_ s: SprintDTO, showWeekends: Bool) -> [String] {
        let dates = s.orderedDates
        if showWeekends { return dates }
        return dates.filter { !DateKey.isWeekend(DateKey.parse($0)) }
    }
}
