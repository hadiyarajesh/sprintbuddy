import Foundation

enum DateKey {
    private static var cal: Calendar { Calendar.current }

    /// Normalizes any Date to local noon of its calendar day (DST-safe).
    static func noon(_ d: Date) -> Date {
        cal.date(bySettingHour: 12, minute: 0, second: 0, of: d) ?? d
    }
    static func iso(_ d: Date) -> String {
        let c = cal.dateComponents([.year, .month, .day], from: d)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }
    static func parse(_ s: String) -> Date {
        let p = s.split(separator: "-").compactMap { Int($0) }
        var c = DateComponents()
        c.year = p.count > 0 ? p[0] : 2000
        c.month = p.count > 1 ? p[1] : 1
        c.day = p.count > 2 ? p[2] : 1
        c.hour = 12
        return cal.date(from: c) ?? Date()
    }
    static func addDays(_ d: Date, _ n: Int) -> Date {
        cal.date(byAdding: .day, value: n, to: noon(d)) ?? d
    }
    static func daysBetween(_ a: Date, _ b: Date) -> Int {
        cal.dateComponents([.day], from: noon(a), to: noon(b)).day ?? 0
    }
    static func today() -> Date { noon(Date()) }
    static func weekday(_ d: Date) -> Int { cal.component(.weekday, from: d) } // 1=Sun...7=Sat
    static func isWeekend(_ d: Date) -> Bool { let w = weekday(d); return w == 1 || w == 7 }
}
