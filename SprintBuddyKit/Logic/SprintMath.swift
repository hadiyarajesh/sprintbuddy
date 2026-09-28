import Foundation

public enum SprintMath {
    public static func generateDays(start: String, weeks: Int, saturdayIsWorkingDay: Bool = false) -> [String: DayDTO] {
        var out: [String: DayDTO] = [:]
        let s = DateKey.parse(start)
        for i in 0..<(weeks * 7) {
            let d = DateKey.addDays(s, i)
            out[DateKey.iso(d)] = DayDTO(status: DateKey.isWeekend(d, saturdayIsWorkingDay: saturdayIsWorkingDay) ? .weekend : .working)
        }
        return out
    }

    public struct Stats: Equatable {
        public var working = 0, logged = 0, leave = 0, holiday = 0
        public init(working: Int = 0, logged: Int = 0, leave: Int = 0, holiday: Int = 0) {
            self.working = working; self.logged = logged; self.leave = leave; self.holiday = holiday
        }
    }

    public static func stats(_ s: SprintDTO) -> Stats {
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

    public static func progressPct(_ s: SprintDTO) -> Int {
        let st = stats(s)
        guard st.working > 0 else { return 0 }
        return Int((Double(st.logged) / Double(st.working) * 100).rounded())
    }

    public enum SprintStatus: String { case active, completed, upcoming }

    public static func status(_ s: SprintDTO, today: String) -> SprintStatus {
        let dates = s.orderedDates
        guard let end = dates.last else { return .upcoming }
        if end < today { return .completed }
        if s.start > today { return .upcoming }
        return .active
    }

    /// A sprint archives itself once its last day is past, unless the user
    /// pinned it either way with a manual archive/unarchive.
    public static func isArchived(_ s: SprintDTO, today: String) -> Bool {
        s.archived ?? (status(s, today: today) == .completed)
    }

    /// The override to store after the user asks for `archived`: `nil` when
    /// that's what the dates would give anyway, so the sprint keeps following
    /// its dates (e.g. unarchiving a still-running sprint lets it auto-archive
    /// when it ends).
    public static func archiveOverride(_ archived: Bool, for s: SprintDTO, today: String) -> Bool? {
        archived == (status(s, today: today) == .completed) ? nil : archived
    }

    /// Dates that hold updates or a note but fall outside a proposed new range,
    /// i.e. what re-dating the sprint would throw away.
    public static func loggedDatesOutside(_ s: SprintDTO, start: String, weeks: Int) -> [String] {
        let first = DateKey.parse(start)
        let end = DateKey.iso(DateKey.addDays(first, weeks * 7 - 1))
        return s.orderedDates.filter { iso in
            guard iso < start || iso > end, let day = s.days[iso] else { return false }
            return !day.updates.isEmpty || !day.privateNote.isEmpty
        }
    }

    public static func dayIndex(_ s: SprintDTO, today: String) -> Int? {
        guard status(s, today: today) == .active else { return nil }
        let total = s.weeks * 7
        var idx = DateKey.daysBetween(DateKey.parse(s.start), DateKey.parse(today)) + 1
        idx = max(1, min(total, idx))
        return idx
    }

    public static func defaultDate(_ s: SprintDTO, today: String) -> String? {
        let dates = s.orderedDates
        guard !dates.isEmpty else { return nil }
        if s.days[today] != nil { return today }
        if let firstWork = dates.first(where: { s.days[$0]?.status != .weekend }) { return firstWork }
        return dates.first
    }

    public static func visibleDates(_ s: SprintDTO, showWeekends: Bool) -> [String] {
        let dates = s.orderedDates
        if showWeekends { return dates }
        return dates.filter { s.days[$0]?.status != .weekend }
    }

    private static let mShort = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
    private static let mLong = ["January","February","March","April","May","June","July","August","September","October","November","December"]
    private static let wShort = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
    private static let wLong = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

    public static func monthShort(_ d: Date) -> String { mShort[Calendar.current.component(.month, from: d) - 1] }
    public static func monthLong(_ d: Date) -> String { mLong[Calendar.current.component(.month, from: d) - 1] }
    public static func weekdayShort(_ d: Date) -> String { wShort[DateKey.weekday(d) - 1] }
    public static func weekdayLong(_ d: Date) -> String { wLong[DateKey.weekday(d) - 1] }
    public static func dayOfMonth(_ d: Date) -> Int { Calendar.current.component(.day, from: d) }

    public static func fmt(_ d: Date) -> String { "\(weekdayShort(d)), \(monthShort(d)) \(dayOfMonth(d))" }
    public static func fmtShort(_ d: Date) -> String { "\(monthShort(d)) \(dayOfMonth(d))" }

    public static func rangeLabel(_ s: SprintDTO) -> String {
        let dates = s.orderedDates
        guard let a = dates.first, let b = dates.last else { return "" }
        let bd = DateKey.parse(b)
        return "\(fmtShort(DateKey.parse(a))) \u{2013} \(fmtShort(bd)), \(Calendar.current.component(.year, from: bd))"
    }
    public static func rangeShort(_ s: SprintDTO) -> String {
        let dates = s.orderedDates
        guard let a = dates.first, let b = dates.last else { return "" }
        return "\(fmtShort(DateKey.parse(a))) \u{2013} \(fmtShort(DateKey.parse(b)))"
    }
}
