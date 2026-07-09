# ScrumBuddy — Daily Sprint Logger Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Recreate the `design_handoff/project/ScrumBuddy.dc.html` prototype as a native SwiftUI + SwiftData macOS app with full feature parity.

**Architecture:** All business logic (date math, day generation, sprint stats/status, JSON export/import, standup-notes formatting) lives in **Foundation-only** value types and free functions, unit-tested via a standalone `swiftc`-compiled runner. SwiftData `@Model` classes provide storage and convert to/from the Codable DTOs. The UI is a custom three-region `HStack` (persistent 274px sidebar · flexible board · collapsible 388px detail pane) in a `.hiddenTitleBar` window, verified by building and launching the app.

**Tech Stack:** Swift 5, SwiftUI, SwiftData, AppKit interop (`NSSavePanel`/`NSOpenPanel`/`NSPasteboard`), Xcode 26.6, macOS 26.5 target.

## Global Constraints

- macOS deployment target: **26.5**. Swift version: **5.0**.
- Bundle id: `com.hadiyarajesh.SprintBuddy`. Do not change signing/team settings.
- The project uses `PBXFileSystemSynchronizedRootGroup` (objectVersion 77): **create new source files anywhere under `SprintBuddy/`** and they are compiled automatically. Do **not** hand-add `PBXBuildFile`/`PBXFileReference` entries.
- **Logic files** (`SprintBuddy/Models/`, `SprintBuddy/Persistence/*Codec*`, `SprintBuddy/Logic/`) import **Foundation only** — never SwiftUI or SwiftData — so they compile under `swiftc` for unit tests. SwiftData model files are separate.
- Source of truth for all visual values (hex colors, px sizes, paddings, radii, copy strings) is `design_handoff/project/ScrumBuddy.dc.html` and its `_ds/.../tokens/colors.css`. The older `uploads/screen.png` is superseded — do not follow it.
- Fonts: **system SF Pro only** (no bundled fonts). First launch shows the empty state (no seed data).
- Export/import JSON schema: `{app:"ScrumBuddy", schema:5, exportedAt:<ISO8601>, sprints:[{id,name,description,start:"YYYY-MM-DD",weeks,days:{"YYYY-MM-DD":{status,privateNote,updates:[{id,type,text}]}}}]}`. Day status values: `working|leave|holiday|weekend`. Update type values: `done|doing|blocker`.
- Build command (used as the "verify" for UI tasks):
  `xcodebuild -project SprintBuddy.xcodeproj -scheme SprintBuddy -destination 'platform=macOS' build`
- Logic unit-test harness: compile the Foundation-only sources plus the test file with `swiftc` and run the binary; the runner exits non-zero on any failed expectation. Scratchpad dir for the binary: `/private/tmp/claude-501/-Users-hadiyarajesh-Documents-Projects-SprintBuddy/*/scratchpad`.
- End every commit message with:
  `Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>`

---

## File Structure

```
SprintBuddy/
  SprintBuddyApp.swift          // @main App, ModelContainer, window config (MODIFY)
  ContentView.swift             // 3-region layout host + AppState (REPLACE stub)
  SprintBuddy.entitlements      // add read-write user-selected files (CREATE + wire)
  Models/
    DomainDTO.swift             // SprintDTO, DayDTO, UpdateDTO, DayStatus, UpdateType (Foundation-only)
    DateKey.swift               // ISO "YYYY-MM-DD" <-> Date helpers (Foundation-only)
  Logic/
    SprintMath.swift            // day generation, status, stats, labels (Foundation-only)
    StandupFormatter.swift      // exportText(sprint) (Foundation-only)
  Persistence/
    ScrumBuddyCodec.swift       // encode/decode the export JSON (Foundation-only)
    SprintStore.swift           // SwiftData <-> DTO bridge, export/import service
  Storage/
    SprintModels.swift          // @Model Sprint, Day, DayUpdate + DTO conversion
  Theme/
    Theme.swift                 // color tokens (light/dark), typography, radii
    Components.swift            // Pill, TypeTag, SBToggle, IconButton, CardStyle
  Views/
    AppState.swift              // ObservableObject: selection + @AppStorage prefs
    Sidebar/
      SidebarView.swift
      SprintRow.swift
      SettingsPopover.swift
      HelpPopover.swift
    Board/
      BoardView.swift
      OverviewCard.swift
      DayGrid.swift
      DayCell.swift
      EmptyStateView.swift
    Detail/
      DetailPane.swift
      UpdateComposer.swift
      UpdateRow.swift
      OffStateView.swift
      CollapsedStrip.swift
    Modals/
      NewSprintSheet.swift
      StandupNotesSheet.swift
      DeleteSprintSheet.swift
      ImportWarningSheet.swift
tests/logic/                    // swiftc test runners (NOT in the app target)
  DateKeyTests.swift
  SprintMathTests.swift
  StandupFormatterTests.swift
  CodecTests.swift
  TestSupport.swift             // expect()/summary() harness
```

---

## Task 1: Test harness + DateKey helpers (TDD)

**Files:**
- Create: `tests/logic/TestSupport.swift`
- Create: `SprintBuddy/Models/DateKey.swift`
- Test: `tests/logic/DateKeyTests.swift`

**Interfaces:**
- Produces: `enum DateKey { static func iso(_ d: Date) -> String; static func parse(_ s: String) -> Date; static func addDays(_ d: Date, _ n: Int) -> Date; static func daysBetween(_ a: Date, _ b: Date) -> Int; static func today() -> Date }`. All dates use the **current calendar at local noon** to avoid DST edge cases. `parse` expects `"YYYY-MM-DD"`.
- `TestSupport`: `func expect(_ cond: Bool, _ msg: String)`, `func expectEqual<T: Equatable>(_ a: T, _ b: T, _ msg: String)`, `func summary() -> Never` (prints `ALL PASS` and exits 0, or prints failures and exits 1). A global `let t = Harness()`.

- [ ] **Step 1: Write the test harness**

`tests/logic/TestSupport.swift`:
```swift
import Foundation

final class Harness {
    private var failures: [String] = []
    private var passed = 0
    func expect(_ cond: Bool, _ msg: String) {
        if cond { passed += 1 } else { failures.append("FAIL: \(msg)") }
    }
    func expectEqual<T: Equatable>(_ a: T, _ b: T, _ msg: String) {
        expect(a == b, "\(msg) (got \(a), want \(b))")
    }
    func summary() -> Never {
        if failures.isEmpty { print("ALL PASS (\(passed) checks)"); exit(0) }
        failures.forEach { print($0) }
        print("\(failures.count) FAILED, \(passed) passed"); exit(1)
    }
}
let t = Harness()
```

- [ ] **Step 2: Write the failing test**

`tests/logic/DateKeyTests.swift`:
```swift
import Foundation

let d = DateKey.parse("2026-07-01")
t.expectEqual(DateKey.iso(d), "2026-07-01", "round-trip iso")
t.expectEqual(DateKey.iso(DateKey.addDays(d, 13)), "2026-07-14", "addDays 13")
t.expectEqual(DateKey.daysBetween(DateKey.parse("2026-07-01"), DateKey.parse("2026-07-09")), 8, "daysBetween")
t.expectEqual(DateKey.iso(DateKey.addDays(DateKey.parse("2026-03-08"), 1)), "2026-03-09", "DST spring-forward day")
t.summary()
```

- [ ] **Step 3: Run to verify it fails**

Run: `swiftc -o "$SP/run1" SprintBuddy/Models/DateKey.swift tests/logic/TestSupport.swift tests/logic/DateKeyTests.swift` (where `SP` is the scratchpad dir).
Expected: FAIL — compile error, `DateKey` not found.

- [ ] **Step 4: Implement DateKey**

`SprintBuddy/Models/DateKey.swift`:
```swift
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
```

- [ ] **Step 5: Run to verify it passes**

Run: `swiftc -o "$SP/run1" SprintBuddy/Models/DateKey.swift tests/logic/TestSupport.swift tests/logic/DateKeyTests.swift && "$SP/run1"`
Expected: `ALL PASS (4 checks)`

- [ ] **Step 6: Commit**

```bash
git add SprintBuddy/Models/DateKey.swift tests/logic/TestSupport.swift tests/logic/DateKeyTests.swift
git commit -m "Add DateKey helpers with test harness"
```

---

## Task 2: Domain DTOs (TDD)

**Files:**
- Create: `SprintBuddy/Models/DomainDTO.swift`
- Test: `tests/logic/DomainDTOTests.swift`

**Interfaces:**
- Consumes: `DateKey`.
- Produces:
  - `enum DayStatus: String, Codable, CaseIterable { case working, leave, holiday, weekend }`
  - `enum UpdateType: String, Codable, CaseIterable { case done, doing, blocker }`
  - `struct UpdateDTO: Codable, Equatable { var id: String; var type: UpdateType; var text: String }`
  - `struct DayDTO: Codable, Equatable { var status: DayStatus; var privateNote: String; var updates: [UpdateDTO] }` — custom `Codable` so `privateNote`/`updates` default to `""`/`[]` when absent; a legacy `note: String?` key, when present and non-empty and `updates` absent, becomes one `done` update per non-empty line.
  - `struct SprintDTO: Codable, Equatable { var id: String; var name: String; var description: String; var start: String; var weeks: Int; var days: [String: DayDTO] }` — `description` defaults to `""` if absent.
  - `var SprintDTO.orderedDates: [String]` → `days.keys.sorted()`.

- [ ] **Step 1: Write the failing test**

`tests/logic/DomainDTOTests.swift`:
```swift
import Foundation

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
```

- [ ] **Step 2: Run to verify it fails**

Run: `swiftc -o "$SP/run2" SprintBuddy/Models/DateKey.swift SprintBuddy/Models/DomainDTO.swift tests/logic/TestSupport.swift tests/logic/DomainDTOTests.swift`
Expected: FAIL — `SprintDTO` not found.

- [ ] **Step 3: Implement DomainDTO**

`SprintBuddy/Models/DomainDTO.swift`:
```swift
import Foundation

enum DayStatus: String, Codable, CaseIterable { case working, leave, holiday, weekend }
enum UpdateType: String, Codable, CaseIterable { case done, doing, blocker }

struct UpdateDTO: Codable, Equatable {
    var id: String
    var type: UpdateType
    var text: String
}

struct DayDTO: Codable, Equatable {
    var status: DayStatus
    var privateNote: String
    var updates: [UpdateDTO]

    init(status: DayStatus, privateNote: String = "", updates: [UpdateDTO] = []) {
        self.status = status; self.privateNote = privateNote; self.updates = updates
    }
    enum CodingKeys: String, CodingKey { case status, privateNote, updates, note }
    init(from dec: Decoder) throws {
        let c = try dec.container(keyedBy: CodingKeys.self)
        status = (try? c.decode(DayStatus.self, forKey: .status)) ?? .working
        privateNote = (try? c.decode(String.self, forKey: .privateNote)) ?? ""
        if let ups = try? c.decode([UpdateDTO].self, forKey: .updates) {
            updates = ups
        } else if let note = try? c.decode(String.self, forKey: .note) {
            updates = note.split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .filter { !$0.isEmpty }
                .map { UpdateDTO(id: UUID().uuidString, type: .done, text: $0) }
        } else { updates = [] }
    }
    func encode(to enc: Encoder) throws {
        var c = enc.container(keyedBy: CodingKeys.self)
        try c.encode(status, forKey: .status)
        try c.encode(privateNote, forKey: .privateNote)
        try c.encode(updates, forKey: .updates)
    }
}

struct SprintDTO: Codable, Equatable {
    var id: String
    var name: String
    var description: String
    var start: String
    var weeks: Int
    var days: [String: DayDTO]

    init(id: String, name: String, description: String = "", start: String, weeks: Int, days: [String: DayDTO]) {
        self.id = id; self.name = name; self.description = description
        self.start = start; self.weeks = weeks; self.days = days
    }
    enum CodingKeys: String, CodingKey { case id, name, description, start, weeks, days }
    init(from dec: Decoder) throws {
        let c = try dec.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        description = (try? c.decode(String.self, forKey: .description)) ?? ""
        start = try c.decode(String.self, forKey: .start)
        weeks = try c.decode(Int.self, forKey: .weeks)
        days = try c.decode([String: DayDTO].self, forKey: .days)
    }
    var orderedDates: [String] { days.keys.sorted() }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `swiftc -o "$SP/run2" SprintBuddy/Models/DateKey.swift SprintBuddy/Models/DomainDTO.swift tests/logic/TestSupport.swift tests/logic/DomainDTOTests.swift && "$SP/run2"`
Expected: `ALL PASS (6 checks)`

- [ ] **Step 5: Commit**

```bash
git add SprintBuddy/Models/DomainDTO.swift tests/logic/DomainDTOTests.swift
git commit -m "Add domain DTOs with legacy-note migration"
```

---

## Task 3: SprintMath (TDD)

**Files:**
- Create: `SprintBuddy/Logic/SprintMath.swift`
- Test: `tests/logic/SprintMathTests.swift`

**Interfaces:**
- Consumes: `DateKey`, `DomainDTO`.
- Produces `enum SprintMath`:
  - `static func generateDays(start: String, weeks: Int) -> [String: DayDTO]` — `weeks*7` days from `start`; Sat/Sun → `.weekend`, else `.working`; `privateNote:""`, `updates:[]`.
  - `struct Stats: Equatable { var working, logged, leave, holiday: Int }`
  - `static func stats(_ s: SprintDTO) -> Stats` — working = count status==working; logged = working days with ≥1 update; leave/holiday counts.
  - `static func progressPct(_ s: SprintDTO) -> Int` — `working==0 ? 0 : round(logged/working*100)`.
  - `enum SprintStatus: String { case active, completed, upcoming }`
  - `static func status(_ s: SprintDTO, today: String) -> SprintStatus` — end<today→completed; start>today→upcoming; else active.
  - `static func dayIndex(_ s: SprintDTO, today: String) -> Int?` — active only: `daysBetween(start,today)+1`, clamped to `1...weeks*7`.
  - `static func defaultDate(_ s: SprintDTO, today: String) -> String?` — today if present; else first working date; else first date.
  - `static func visibleDates(_ s: SprintDTO, showWeekends: Bool) -> [String]`.

- [ ] **Step 1: Write the failing test**

`tests/logic/SprintMathTests.swift`:
```swift
import Foundation

let days = SprintMath.generateDays(start: "2026-07-01", weeks: 2)
t.expectEqual(days.count, 14, "14 days generated")
t.expectEqual(days["2026-07-04"]!.status, .weekend, "Sat is weekend")   // 2026-07-04 is Sat
t.expectEqual(days["2026-07-01"]!.status, .working, "Wed is working")

var s = SprintDTO(id: "s", name: "n", start: "2026-07-01", weeks: 2, days: days)
s.days["2026-07-01"]!.updates = [UpdateDTO(id: "u1", type: .done, text: "x")]
s.days["2026-07-03"]!.status = .holiday
s.days["2026-07-02"]!.status = .leave
let st = SprintMath.stats(s)
t.expectEqual(st.leave, 1, "1 leave")
t.expectEqual(st.holiday, 1, "1 holiday")
t.expectEqual(st.logged, 1, "1 logged")
t.expect(st.working >= 8, "working excludes weekend/leave/holiday")
t.expectEqual(SprintMath.status(s, today: "2026-07-05"), .active, "spans today -> active")
t.expectEqual(SprintMath.status(s, today: "2026-07-30"), .completed, "past -> completed")
t.expectEqual(SprintMath.status(s, today: "2026-06-01"), .upcoming, "future -> upcoming")
t.expectEqual(SprintMath.dayIndex(s, today: "2026-07-05"), 5, "day 5 of 14")
t.expectEqual(SprintMath.defaultDate(s, today: "2026-07-05"), "2026-07-05", "today is default")
t.summary()
```

- [ ] **Step 2: Run to verify it fails**

Run: `swiftc -o "$SP/run3" SprintBuddy/Models/DateKey.swift SprintBuddy/Models/DomainDTO.swift SprintBuddy/Logic/SprintMath.swift tests/logic/TestSupport.swift tests/logic/SprintMathTests.swift`
Expected: FAIL — `SprintMath` not found.

- [ ] **Step 3: Implement SprintMath**

`SprintBuddy/Logic/SprintMath.swift`:
```swift
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
```

- [ ] **Step 4: Run to verify it passes**

Run: `swiftc -o "$SP/run3" SprintBuddy/Models/DateKey.swift SprintBuddy/Models/DomainDTO.swift SprintBuddy/Logic/SprintMath.swift tests/logic/TestSupport.swift tests/logic/SprintMathTests.swift && "$SP/run3"`
Expected: `ALL PASS (12 checks)`

- [ ] **Step 5: Commit**

```bash
git add SprintBuddy/Logic/SprintMath.swift tests/logic/SprintMathTests.swift
git commit -m "Add SprintMath: day generation, stats, status, indices"
```

---

## Task 4: Date labels + StandupFormatter (TDD)

**Files:**
- Modify: `SprintBuddy/Logic/SprintMath.swift` (add label helpers)
- Create: `SprintBuddy/Logic/StandupFormatter.swift`
- Test: `tests/logic/StandupFormatterTests.swift`

**Interfaces:**
- Adds to `SprintMath`:
  - `static func monthShort(_ d: Date) -> String` (`Jan`…`Dec`), `monthLong`, `weekdayShort` (`Sun`…`Sat`), `weekdayLong`.
  - `static func fmt(_ d: Date) -> String` → `"Tue, Jul 1"`; `fmtShort(_ d: Date)` → `"Jul 1"`.
  - `static func rangeLabel(_ s: SprintDTO) -> String` → `"Jul 1 – Jul 14, 2026"`; `rangeShort(_ s:)` → `"Jul 1 – Jul 14"`. Use en-dash `–`.
- `enum StandupFormatter { static func text(_ s: SprintDTO) -> String }` matching prototype `exportText`:
  - Line 1: `"<name> — <rangeLabel>"` (em-dash).
  - If description non-empty: `"Focus: <desc>"`.
  - `"Logged <logged> of <working> working days · <leave> leave · <holiday> holiday"`.
  - Blank line, then per ordered date: leave→`"<fmt> — Leave"`, holiday→`"<fmt> — Holiday"`, weekend with no updates→skipped, days with updates→`fmt` then `"  - [Done|Doing|Blocker] <text>"` per update.

- [ ] **Step 1: Write the failing test**

`tests/logic/StandupFormatterTests.swift`:
```swift
import Foundation

var days = SprintMath.generateDays(start: "2026-07-01", weeks: 1)
days["2026-07-01"]!.updates = [UpdateDTO(id: "u", type: .done, text: "shipped")]
days["2026-07-02"]!.status = .leave
var s = SprintDTO(id: "s", name: "Sprint 24.14", description: "APIs", start: "2026-07-01", weeks: 1, days: days)
let out = StandupFormatter.text(s)
t.expect(out.hasPrefix("Sprint 24.14 — Jul 1 – Jul 7, 2026"), "header line")
t.expect(out.contains("Focus: APIs"), "focus line")
t.expect(out.contains("Wed, Jul 1"), "logged day label")
t.expect(out.contains("  - [Done] shipped"), "bulleted update")
t.expect(out.contains("Thu, Jul 2 — Leave"), "leave line")
t.expectEqual(SprintMath.rangeShort(s), "Jul 1 – Jul 7", "range short")
t.summary()
```

- [ ] **Step 2: Run to verify it fails**

Run: `swiftc -o "$SP/run4" SprintBuddy/Models/DateKey.swift SprintBuddy/Models/DomainDTO.swift SprintBuddy/Logic/SprintMath.swift SprintBuddy/Logic/StandupFormatter.swift tests/logic/TestSupport.swift tests/logic/StandupFormatterTests.swift`
Expected: FAIL — label helpers / `StandupFormatter` not found.

- [ ] **Step 3: Implement label helpers + StandupFormatter**

Append to `SprintBuddy/Logic/SprintMath.swift` (inside `enum SprintMath`):
```swift
    private static let mShort = ["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"]
    private static let mLong = ["January","February","March","April","May","June","July","August","September","October","November","December"]
    private static let wShort = ["Sun","Mon","Tue","Wed","Thu","Fri","Sat"]
    private static let wLong = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"]

    static func monthShort(_ d: Date) -> String { mShort[Calendar.current.component(.month, from: d) - 1] }
    static func monthLong(_ d: Date) -> String { mLong[Calendar.current.component(.month, from: d) - 1] }
    static func weekdayShort(_ d: Date) -> String { wShort[DateKey.weekday(d) - 1] }
    static func weekdayLong(_ d: Date) -> String { wLong[DateKey.weekday(d) - 1] }
    static func dayOfMonth(_ d: Date) -> Int { Calendar.current.component(.day, from: d) }

    static func fmt(_ d: Date) -> String { "\(weekdayShort(d)), \(monthShort(d)) \(dayOfMonth(d))" }
    static func fmtShort(_ d: Date) -> String { "\(monthShort(d)) \(dayOfMonth(d))" }

    static func rangeLabel(_ s: SprintDTO) -> String {
        let dates = s.orderedDates
        guard let a = dates.first, let b = dates.last else { return "" }
        let bd = DateKey.parse(b)
        return "\(fmtShort(DateKey.parse(a))) \u{2013} \(fmtShort(bd)), \(Calendar.current.component(.year, from: bd))"
    }
    static func rangeShort(_ s: SprintDTO) -> String {
        let dates = s.orderedDates
        guard let a = dates.first, let b = dates.last else { return "" }
        return "\(fmtShort(DateKey.parse(a))) \u{2013} \(fmtShort(DateKey.parse(b)))"
    }
```

`SprintBuddy/Logic/StandupFormatter.swift`:
```swift
import Foundation

enum StandupFormatter {
    private static let typeLabel: [UpdateType: String] = [.done: "Done", .doing: "Doing", .blocker: "Blocker"]

    static func text(_ s: SprintDTO) -> String {
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
```

- [ ] **Step 4: Run to verify it passes**

Run: `swiftc -o "$SP/run4" SprintBuddy/Models/DateKey.swift SprintBuddy/Models/DomainDTO.swift SprintBuddy/Logic/SprintMath.swift SprintBuddy/Logic/StandupFormatter.swift tests/logic/TestSupport.swift tests/logic/StandupFormatterTests.swift && "$SP/run4"`
Expected: `ALL PASS (6 checks)`

- [ ] **Step 5: Commit**

```bash
git add SprintBuddy/Logic/SprintMath.swift SprintBuddy/Logic/StandupFormatter.swift tests/logic/StandupFormatterTests.swift
git commit -m "Add date labels and standup-notes formatter"
```

---

## Task 5: Export/Import Codec (TDD)

**Files:**
- Create: `SprintBuddy/Persistence/ScrumBuddyCodec.swift`
- Test: `tests/logic/CodecTests.swift`

**Interfaces:**
- Consumes: `DomainDTO`.
- Produces `enum ScrumBuddyCodec`:
  - `struct Export: Codable { var app: String; var schema: Int; var exportedAt: String; var sprints: [SprintDTO] }`
  - `static func encode(_ sprints: [SprintDTO]) -> Data` — `app:"ScrumBuddy"`, `schema:5`, `exportedAt:` ISO8601 now, pretty-printed, keys **not** sorted-escaped.
  - `enum ImportError: Error, Equatable { case notJSON, notScrumBuddy }`
  - `static func decode(_ data: Data) -> Result<[SprintDTO], ImportError>` — invalid JSON→`.notJSON`; must have non-empty `sprints` where each has `id`, `start`, and a `days` object, else `.notScrumBuddy`.

- [ ] **Step 1: Write the failing test**

`tests/logic/CodecTests.swift`:
```swift
import Foundation

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
```

- [ ] **Step 2: Run to verify it fails**

Run: `swiftc -o "$SP/run5" SprintBuddy/Models/DateKey.swift SprintBuddy/Models/DomainDTO.swift SprintBuddy/Logic/SprintMath.swift SprintBuddy/Persistence/ScrumBuddyCodec.swift tests/logic/TestSupport.swift tests/logic/CodecTests.swift`
Expected: FAIL — `ScrumBuddyCodec` not found.

- [ ] **Step 3: Implement ScrumBuddyCodec**

`SprintBuddy/Persistence/ScrumBuddyCodec.swift`:
```swift
import Foundation

enum ScrumBuddyCodec {
    struct Export: Codable { var app: String; var schema: Int; var exportedAt: String; var sprints: [SprintDTO] }
    enum ImportError: Error, Equatable { case notJSON, notScrumBuddy }

    static func encode(_ sprints: [SprintDTO]) -> Data {
        let payload = Export(app: "ScrumBuddy", schema: 5,
                             exportedAt: ISO8601DateFormatter().string(from: Date()),
                             sprints: sprints)
        let enc = JSONEncoder()
        enc.outputFormatting = [.prettyPrinted]
        return (try? enc.encode(payload)) ?? Data()
    }

    static func decode(_ data: Data) -> Result<[SprintDTO], ImportError> {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return .failure(.notJSON)
        }
        guard let rawSprints = obj["sprints"] as? [[String: Any]], !rawSprints.isEmpty else {
            return .failure(.notScrumBuddy)
        }
        let ok = rawSprints.allSatisfy { $0["id"] != nil && $0["start"] != nil && $0["days"] is [String: Any] }
        guard ok else { return .failure(.notScrumBuddy) }
        guard let export = try? JSONDecoder().decode(Export.self, from: data) else {
            return .failure(.notScrumBuddy)
        }
        return .success(export.sprints)
    }
}
```

- [ ] **Step 4: Run to verify it passes**

Run: `swiftc -o "$SP/run5" SprintBuddy/Models/DateKey.swift SprintBuddy/Models/DomainDTO.swift SprintBuddy/Logic/SprintMath.swift SprintBuddy/Persistence/ScrumBuddyCodec.swift tests/logic/TestSupport.swift tests/logic/CodecTests.swift && "$SP/run5"`
Expected: `ALL PASS (6 checks)`

- [ ] **Step 5: Commit**

```bash
git add SprintBuddy/Persistence/ScrumBuddyCodec.swift tests/logic/CodecTests.swift
git commit -m "Add export/import JSON codec with validation"
```

---

## Task 6: SwiftData models + DTO bridge

**Files:**
- Create: `SprintBuddy/Storage/SprintModels.swift`
- Create: `SprintBuddy/Persistence/SprintStore.swift`

**Interfaces:**
- Consumes: `DomainDTO`, `SprintMath`, `ScrumBuddyCodec`.
- Produces (`@Model`, import SwiftData + Foundation):
  - `@Model final class Sprint { var id: String; var name: String; var focus: String; var startISO: String; var weeks: Int; var createdAt: Date; @Relationship(deleteRule: .cascade, inverse: \Day.sprint) var days: [Day] }` with `init(...)`.
  - `@Model final class Day { var dateISO: String; var statusRaw: String; var privateNote: String; @Relationship(deleteRule: .cascade, inverse: \DayUpdate.day) var updates: [DayUpdate]; var sprint: Sprint? }` + `var status: DayStatus` computed over `statusRaw`.
  - `@Model final class DayUpdate { var id: String; var typeRaw: String; var text: String; var sortIndex: Int; var day: Day? }` + `var type: UpdateType` computed.
  - `extension Sprint { func toDTO() -> SprintDTO; static func from(_ dto: SprintDTO) -> Sprint }`.
- Produces `struct SprintStore` (import SwiftData):
  - `static func createSprint(name:focus:startISO:weeks:in context:) -> Sprint` — builds via `SprintMath.generateDays`, inserts model graph.
  - `static func replaceAll(with dtos: [SprintDTO], in context:)` — delete all existing `Sprint`, insert imported.
  - `static func exportData(_ sprints: [Sprint]) -> Data` — map to DTO, `ScrumBuddyCodec.encode`.

- [ ] **Step 1: Implement SprintModels**

`SprintBuddy/Storage/SprintModels.swift`:
```swift
import Foundation
import SwiftData

@Model final class Sprint {
    var id: String = ""
    var name: String = ""
    var focus: String = ""
    var startISO: String = ""
    var weeks: Int = 2
    var createdAt: Date = Date()
    @Relationship(deleteRule: .cascade, inverse: \Day.sprint) var days: [Day] = []

    init(id: String, name: String, focus: String, startISO: String, weeks: Int, createdAt: Date = Date()) {
        self.id = id; self.name = name; self.focus = focus
        self.startISO = startISO; self.weeks = weeks; self.createdAt = createdAt
    }

    func toDTO() -> SprintDTO {
        var dayMap: [String: DayDTO] = [:]
        for d in days {
            let ups = d.updates.sorted { $0.sortIndex < $1.sortIndex }
                .map { UpdateDTO(id: $0.id, type: $0.type, text: $0.text) }
            dayMap[d.dateISO] = DayDTO(status: d.status, privateNote: d.privateNote, updates: ups)
        }
        return SprintDTO(id: id, name: name, description: focus, start: startISO, weeks: weeks, days: dayMap)
    }

    static func from(_ dto: SprintDTO) -> Sprint {
        let s = Sprint(id: dto.id, name: dto.name, focus: dto.description, startISO: dto.start, weeks: dto.weeks)
        for iso in dto.orderedDates {
            let dd = dto.days[iso]!
            let day = Day(dateISO: iso, status: dd.status, privateNote: dd.privateNote)
            for (i, u) in dd.updates.enumerated() {
                day.updates.append(DayUpdate(id: u.id, type: u.type, text: u.text, sortIndex: i))
            }
            s.days.append(day)
        }
        return s
    }
}

@Model final class Day {
    var dateISO: String = ""
    var statusRaw: String = DayStatus.working.rawValue
    var privateNote: String = ""
    @Relationship(deleteRule: .cascade, inverse: \DayUpdate.day) var updates: [DayUpdate] = []
    var sprint: Sprint?

    init(dateISO: String, status: DayStatus, privateNote: String = "") {
        self.dateISO = dateISO; self.statusRaw = status.rawValue; self.privateNote = privateNote
    }
    var status: DayStatus {
        get { DayStatus(rawValue: statusRaw) ?? .working }
        set { statusRaw = newValue.rawValue }
    }
}

@Model final class DayUpdate {
    var id: String = UUID().uuidString
    var typeRaw: String = UpdateType.done.rawValue
    var text: String = ""
    var sortIndex: Int = 0
    var day: Day?

    init(id: String, type: UpdateType, text: String, sortIndex: Int) {
        self.id = id; self.typeRaw = type.rawValue; self.text = text; self.sortIndex = sortIndex
    }
    var type: UpdateType {
        get { UpdateType(rawValue: typeRaw) ?? .doing }
        set { typeRaw = newValue.rawValue }
    }
}
```

- [ ] **Step 2: Implement SprintStore**

`SprintBuddy/Persistence/SprintStore.swift`:
```swift
import Foundation
import SwiftData

struct SprintStore {
    @discardableResult
    static func createSprint(name: String, focus: String, startISO: String, weeks: Int,
                             in context: ModelContext) -> Sprint {
        let dto = SprintDTO(id: "s\(Int(Date().timeIntervalSince1970 * 1000))",
                            name: name, description: focus, start: startISO, weeks: weeks,
                            days: SprintMath.generateDays(start: startISO, weeks: weeks))
        let sprint = Sprint.from(dto)
        context.insert(sprint)
        return sprint
    }

    static func replaceAll(with dtos: [SprintDTO], in context: ModelContext) {
        let existing = (try? context.fetch(FetchDescriptor<Sprint>())) ?? []
        existing.forEach { context.delete($0) }
        dtos.forEach { context.insert(Sprint.from($0)) }
    }

    static func exportData(_ sprints: [Sprint]) -> Data {
        ScrumBuddyCodec.encode(sprints.map { $0.toDTO() })
    }
}
```

- [ ] **Step 3: Verify it builds**

Run: `xcodebuild -project SprintBuddy.xcodeproj -scheme SprintBuddy -destination 'platform=macOS' build`
Expected: `** BUILD SUCCEEDED **` (ContentView still the stub).

- [ ] **Step 4: Commit**

```bash
git add SprintBuddy/Storage/SprintModels.swift SprintBuddy/Persistence/SprintStore.swift
git commit -m "Add SwiftData models and DTO bridge/store"
```

---

## Task 7: Theme tokens + shared components

**Files:**
- Create: `SprintBuddy/Theme/Theme.swift`
- Create: `SprintBuddy/Theme/Components.swift`

**Interfaces:**
- Produces `enum Theme` with a `static func color(_ token: SBColor, _ scheme: ColorScheme) -> Color` plus named `Color` accessors, OR (preferred) a `SBPalette` struct resolved from `ColorScheme` exposing every token used by the UI. Port values verbatim from `design_handoff/project/ScrumBuddy.dc.html` `:root` (lines ~20-59) and `_ds/.../tokens/colors.css`. Required tokens (light / dark):
  - Brand: `blue #2a76e1`; `navy #18407b`; `textNavy #263271` (dark `#e6ebf5`); `ink`.
  - Greys `grey1..grey6` (dark overrides from the `data-sb-theme="dark"` block, e.g. `grey2 #757575`→dark `#98a3b7`, `grey6 #d4d4d4`→dark `#333a49`).
  - Semantic: `error #de0606`, `success #4eb55c`, `successDark #379143`, `warning #f8a213`.
  - Surfaces: `white #ffffff`→dark `#1b202b`; `sidebar #f7f9fc`→`#14181f`; `board` gradient light `#f2f5fa→#e8edf5` dark `#10141c→#0b0e14`; `border #e9edf4`→`#282e3a`; `border2`; `chip #eaeef5`→`#232a37`; `hover`, `hover2`, `navActive #dce8fc`→rgba, `todayBg #eaf2fe`→rgba; `inputSoft #fbfcfe`→`#12161f`; `muted #eef1f6`→`#1b212c`; `toggleOff #cfd6e2`→`#3a4152`; `scrollbar`.
  - Tints/borders: `blueTint/-Border`, `redTint/-Border`, `amberTint/-Border`, `greenTint`; `dashed #cfd8e6`, `dashedWarn #f0c675`; `cardBorder rgba(19,19,76,0.06)`, `cardBorder2`; `leaveBorder`, `holidayBorder`, `weekendBorder`.
  - Window shadow tokens.
  - `holidayText` = `#b97907` (both schemes, per prototype).
- `Radius`: `md 9`, `lg 14`, card `18`, cell `14`, pill `999`.
- `Components.swift` — reusable views used across the app (exact styling per prototype):
  - `struct StatusPill` (dot + label + tint bg) for sprint status.
  - `struct StatPill` (value + label, tinted, bordered) for overview stats.
  - `struct TypeTag` (Done/Doing/Blocker rounded tag).
  - `struct TypeChipButton` (selectable pill for the composer).
  - `struct SBToggle` (38×22 track, 18 knob, animates left 2↔18) bound to a `Bool`.
  - `struct SectionHeaderButton` (chevron + uppercase label + count chip).
  - `struct IconButton` (SF Symbol, square, hover bg).

- [ ] **Step 1: Implement Theme (palette resolved by ColorScheme)**

Create `SprintBuddy/Theme/Theme.swift` with a `SBPalette` struct built from `ColorScheme`, using `Color(hex:)` and `Color(red:green:blue:opacity:)` for rgba tokens. Include a `Color(hex:)` initializer. Provide `@Environment`-friendly access via `EnvironmentKey` `\.palette` defaulting to `.light`, and a `View.sbPalette(_:)` helper; `ContentView` injects `SBPalette(scheme)` based on `@Environment(\.colorScheme)`. Board gradient exposed as `LinearGradient`.

(Transcribe each token's light and dark hex/rgba from the prototype `:root` and `html[data-sb-theme="dark"]` blocks — they are the exact values.)

- [ ] **Step 2: Implement Components**

Create `SprintBuddy/Theme/Components.swift` with the structs listed under Interfaces. Match measurements from the prototype:
- `SBToggle`: track `38×22`, radius pill, knob `18×18` white with shadow, `on ? blue : toggleOff`, `.animation(.easeInOut(duration:0.2))`.
- `TypeTag`: font 10, weight bold, uppercase, padding `3×8`, pill radius, `color`/`tint` per type via `typeMeta`.
- `StatPill`: value 16/bold + label 11, padding `6×11`, radius 9, tint bg + 1px tint border.
- `StatusPill`: dot 7×7 + label 12/semibold, padding `3×11`, pill.
- Add `enum UpdateMeta { static func label/color/tint(_ type: UpdateType, _ p: SBPalette) }` mirroring `typeMeta()` (done→success/greenTint, doing→blue/blueTint, blocker→error/redTint).

- [ ] **Step 3: Verify it builds**

Run: `xcodebuild -project SprintBuddy.xcodeproj -scheme SprintBuddy -destination 'platform=macOS' build`
Expected: `** BUILD SUCCEEDED **`.

- [ ] **Step 4: Commit**

```bash
git add SprintBuddy/Theme/
git commit -m "Add theme tokens (light/dark) and shared components"
```

---

## Task 8: App shell, window chrome, AppState, empty state

**Files:**
- Modify: `SprintBuddy/SprintBuddyApp.swift`
- Replace: `SprintBuddy/ContentView.swift`
- Create: `SprintBuddy/Views/AppState.swift`
- Create: `SprintBuddy/Views/Board/EmptyStateView.swift`

**Interfaces:**
- Consumes: models, `SprintStore`, `SprintMath`, Theme.
- `SprintBuddyApp`: `WindowGroup { ContentView() }.modelContainer(for: [Sprint.self, Day.self, DayUpdate.self])`, `.windowStyle(.hiddenTitleBar)`, `.defaultSize(width: 1240, height: 820)`, `.windowToolbarStyle(.unifiedCompact)`.
- `final class AppState: ObservableObject`: `@Published var selectedSprintID: String?`, `@Published var selectedDateISO: String?`, `@Published var paneCollapsed: Bool` (persisted via `@AppStorage` wrappers or mirrored to `UserDefaults` on didSet), `@Published var activeOpen/archiveOpen`, plus sheet/popover flags: `newSprintOpen`, `standupOpen`, `deleteOpen`, `importWarnOpen`, `settingsOpen`, `helpOpen`, `statusMenuOpen`, and `pendingImport: [SprintDTO]?`, `importError: String`. Prefs: `@AppStorage("theme") themeRaw`, `@AppStorage("showWeekends")`, `@AppStorage("highlightUnlogged")`.
- `ContentView`: reads `@Query(sort: \Sprint.createdAt, order: .reverse) var sprints`, resolves active sprint DTO, lays out the three regions, applies `.preferredColorScheme` from theme, injects palette.

- [ ] **Step 1: Configure the app + window**

Rewrite `SprintBuddyApp.swift` per Interfaces (model container + window style). Set the window min size via `ContentView`'s `.frame(minWidth: 1180, minHeight: 720)`.

- [ ] **Step 2: Implement AppState**

Create `SprintBuddy/Views/AppState.swift`. Back durable UI state (`selectedSprintID`, `selectedDateISO`, `paneCollapsed`, `activeOpen`, `archiveOpen`) with `UserDefaults` in `didSet`; load in `init()`. `theme` returns a `ColorScheme?` (`auto→nil`, `light→.light`, `dark→.dark`).

- [ ] **Step 3: Implement ContentView shell + empty state**

`ContentView`: three-region `HStack(spacing: 0)`:
- Sidebar placeholder (fixed 274) — real content in Task 9.
- Board area: if no active sprint → `EmptyStateView(onNew:)`; else board placeholder.
- Detail region: only when a sprint+day exist (Task 12).
Wrap in `ZStack(alignment: .topLeading)`; background = board gradient. Apply `.preferredColorScheme(appState.theme)`. Handle "New Sprint" by toggling `appState.newSprintOpen` (sheet added in Task 11, stub for now with an empty `.sheet`).
`EmptyStateView`: centered calendar SF Symbol (`calendar`, 46pt, grey5), "No sprints yet" (16/medium), subtitle (13/grey2), and a "New Sprint" button (blue, `plus` icon). Match prototype lines 299-308.

- [ ] **Step 4: Verify by building and launching**

Run: `xcodebuild ... build` → `** BUILD SUCCEEDED **`.
Then launch and screenshot using the `run` skill (or `open` the built `.app` from `xcodebuild -showBuildSettings` `BUILT_PRODUCTS_DIR`). Confirm: window has native traffic lights, no title bar, empty state centered, "New Sprint" visible.

- [ ] **Step 5: Commit**

```bash
git add SprintBuddy/SprintBuddyApp.swift SprintBuddy/ContentView.swift SprintBuddy/Views/AppState.swift SprintBuddy/Views/Board/EmptyStateView.swift
git commit -m "Add app shell, hidden-titlebar window, AppState, empty state"
```

---

## Task 9: Sidebar

**Files:**
- Create: `SprintBuddy/Views/Sidebar/SidebarView.swift`
- Create: `SprintBuddy/Views/Sidebar/SprintRow.swift`
- Modify: `SprintBuddy/ContentView.swift` (mount sidebar)

**Interfaces:**
- Consumes: `sprints: [Sprint]`, `AppState`, `SprintMath` (status/rangeShort), Theme.
- `SidebarView(sprints:appState:onNewSprint:)`: 274px column, `sbSidebar` bg, trailing 1px border.
  - Top spacer of ~28pt to clear traffic lights, then brand row: 38×38 rounded-11 gradient square (`#2a76e1→#153a71`) with `square.grid.2x2` (Dashboard) glyph, "ScrumBuddy" 18/bold blue, "v2.4.0" 11/grey3.
  - Scrollable sections: partition sprints via `SprintMath.status` — `completed`→Archive, else Active; each sorted by start descending. `SectionHeaderButton` toggles `activeOpen`/`archiveOpen`; count chip. Rows via `SprintRow`.
  - "New Sprint" secondary button (block) → `onNewSprint`.
  - Footer (top border): Settings + Help buttons toggling popovers (Task 12 fills popovers; here wire the buttons + `.popover` anchors).
- `SprintRow(sprint:isSelected:onSelect:)`: `calendar` icon + name (13.5, weight 700 if selected else 500, blue if selected) + rangeShort (11.5/grey2); selected bg `navActive`, radius 10; hover bg.

- [ ] **Step 1: Implement SprintRow + SidebarView** per Interfaces; selection sets `appState.selectedSprintID` and `selectedDateISO = SprintMath.defaultDate(dto, today:)`, `paneCollapsed = false`.
- [ ] **Step 2: Mount in ContentView**, replacing the sidebar placeholder; default `selectedSprintID` to the newest sprint when nil.
- [ ] **Step 3: Verify** build + launch. With no sprints, Active(0)/Archive(0) show, "New Sprint" present. (Populated states covered after Task 11.)
- [ ] **Step 4: Commit**

```bash
git add SprintBuddy/Views/Sidebar/ SprintBuddy/ContentView.swift
git commit -m "Add sidebar with active/archive sections and sprint rows"
```

---

## Task 10: Board — overview card + day grid

**Files:**
- Create: `SprintBuddy/Views/Board/BoardView.swift`
- Create: `SprintBuddy/Views/Board/OverviewCard.swift`
- Create: `SprintBuddy/Views/Board/DayGrid.swift`
- Create: `SprintBuddy/Views/Board/DayCell.swift`
- Modify: `SprintBuddy/ContentView.swift`

**Interfaces:**
- Consumes: active `Sprint`, its `SprintDTO`, `AppState`, `SprintMath`, Theme, components.
- `BoardView(sprint:appState:onDelete:onStandup:)`: scroll view, `maxWidth: 1000`, padding `26×30`; `OverviewCard` then `DayGrid`.
- `OverviewCard`: name 25/bold blue; `StatusPill` (active/completed/upcoming → success/grey/warning); range + `"· <weeks>-week sprint"`; `"Day N of M"` chip when active; editable focus `TextField` (binds to `sprint.focus`, placeholder "Add a focus for this sprint…"); progress bar (8pt track, gradient blue→green fill, `progressPct`); `StatPill`s (logged `logged/working`; leave; holiday — only when >0); action buttons: Standup Notes (`square.and.arrow.up`/`text.alignleft`) → `onStandup`, Delete (`trash`, error outline) → `onDelete`.
- `DayGrid`: `LazyVGrid` 5 columns, spacing 12; iterate `SprintMath.visibleDates(dto, showWeekends:)`; render `DayCell`.
- `DayCell(dto day:isoDate:isToday:isSelected:notLogged:onSelect:)`: min-height 148, radius 14, padding `12×13`. Header: `dd/MM` (15/bold) + weekday (11/grey3) + optional "Today" pill; optional status dot (leave→error, holiday→warning). Body by status:
  - working+logged: up to 3 update preview lines (dot in type color + text, single-line truncated) + `"+N more"`.
  - working+empty (not past): centered 30×30 circle with `plus`.
  - working+past+unlogged (when highlightUnlogged): dashed warn border + "Not logged" (warning, `exclamationmark.triangle`).
  - leave/holiday: bottom status label ("On leave"/"Holiday").
  - weekend: muted bg, weekend border, no shadow.
  - Borders/emphasis exactly per prototype `buildCells` (lines 918-946): empty working → 1.5px dashed; today (unselected) → 1.5px blue + todayBg; selected → 2px blue + 3px focus ring (`shadow`/overlay) + todayBg for working.

- [ ] **Step 1: Implement DayCell** covering all states above (use an enum to pick the branch); expose a `border`/`fill`/`overlay` computed from state.
- [ ] **Step 2: Implement DayGrid + OverviewCard + BoardView**; focus `TextField` writes back to the model (`sprint.focus`); progress + stats from `SprintMath`.
- [ ] **Step 3: Mount BoardView in ContentView** for the active sprint; cell `onSelect` sets `appState.selectedDateISO`, `paneCollapsed=false`.
- [ ] **Step 4: Verify** build + launch. Requires a sprint — create one via the New Sprint sheet after Task 11, or temporarily seed one in a `#Preview`. Confirm grid renders 5-wide with correct cell variants and today/selected emphasis. Compare against prototype.
- [ ] **Step 5: Commit**

```bash
git add SprintBuddy/Views/Board/ SprintBuddy/ContentView.swift
git commit -m "Add board overview card and day grid with all cell states"
```

---

## Task 11: New Sprint sheet (create flow end-to-end)

**Files:**
- Create: `SprintBuddy/Views/Modals/NewSprintSheet.swift`
- Modify: `SprintBuddy/ContentView.swift` (present sheet, wire create)

**Interfaces:**
- Consumes: `AppState`, `ModelContext`, `SprintStore`, `SprintMath`.
- `NewSprintSheet(isPresented:onCreate:)`: fields — name (`TextField`, required, inline error "Enter a sprint name"), focus (optional), start date (`DatePicker`, `.field`/graphical, default today), duration (`Picker`: 1–4 weeks, default 2). Preview line: `"Creates <weeks*7> day cards · <fmt(start)> – <fmt(end)>. Weekends are marked automatically."`. Buttons: Cancel / Create Sprint. Width ~480. `onCreate(name,focus,startISO,weeks)`.
- ContentView create handler: `SprintStore.createSprint(...)`, set `selectedSprintID`, `selectedDateISO = defaultDate`, close sheet.

- [ ] **Step 1: Implement NewSprintSheet** with validation + live preview.
- [ ] **Step 2: Wire `.sheet(isPresented: $appState.newSprintOpen)`** in ContentView to create + select the sprint.
- [ ] **Step 3: Verify** build + launch: click New Sprint → fill → Create → sprint appears in sidebar Active, board renders its grid, detail pane opens on default day.
- [ ] **Step 4: Commit**

```bash
git add SprintBuddy/Views/Modals/NewSprintSheet.swift SprintBuddy/ContentView.swift
git commit -m "Add New Sprint sheet and end-to-end create flow"
```

---

## Task 12: Detail pane (expanded, collapsed strip, off-states)

**Files:**
- Create: `SprintBuddy/Views/Detail/DetailPane.swift`
- Create: `SprintBuddy/Views/Detail/UpdateComposer.swift`
- Create: `SprintBuddy/Views/Detail/UpdateRow.swift`
- Create: `SprintBuddy/Views/Detail/OffStateView.swift`
- Create: `SprintBuddy/Views/Detail/CollapsedStrip.swift`
- Modify: `SprintBuddy/ContentView.swift`

**Interfaces:**
- Consumes: active `Sprint`, selected `Day`, `AppState`, Theme, components.
- `DetailPane(sprint:day:appState:)`: 388px, `white` bg, leading 1px border. Header: long date (`monthLong d, yyyy`, 22/bold) + sub (Today/weekdayLong) + status menu button (`.popover` or menu) offering Working/Leave/Holiday/Weekend (Weekend only if the date is Sat/Sun) — writing `day.status`. Floating collapse button: 26×26 circle at leading `-13`, top `28` (overlay with negative offset), `chevron.right` → `paneCollapsed=true`.
  - Working day: `UpdateComposer` + Updates list card (count chip; `UpdateRow`s or "No updates yet") + Private note `TextEditor` (binds `day.privateNote`, placeholder) + "Saved automatically" (`checkmark.seal`, success).
  - Non-working: `OffStateView` (icon tile + title + subtitle per status; copy from prototype `offMap` lines 1096-1100).
- `UpdateComposer(draft binding, type binding, onAdd)`: `TextEditor` (58pt), Done/Doing/Blocker `TypeChipButton`s, Add button (blue; `⌘/Ctrl+Enter` via `.onKeyPress`), disabled/0.55 opacity when empty.
- `UpdateRow(update:isEditing:...)`: view mode = type tag + text + edit/delete icon buttons; edit mode = `TextEditor` + type chips + Cancel/Save. Empty save deletes. Mutations write the model + `sortIndex` preserved.
- `CollapsedStrip(dateLong:onExpand:)`: 54px `sbSidebar` column, expand button (`chevron.left`) + vertical-text date; whole strip tap → expand.

- [ ] **Step 1: Implement UpdateRow + UpdateComposer** (add/edit/delete against the model; new update `sortIndex = (max existing)+1`).
- [ ] **Step 2: Implement OffStateView + CollapsedStrip + DetailPane** (status menu, collapse button, sections).
- [ ] **Step 3: Mount in ContentView**: show `DetailPane` when `!paneCollapsed`, else `CollapsedStrip`, only when a sprint+selected day exist. Animate with `.transition(.move(edge: .trailing))` + `withAnimation` on collapse toggle.
- [ ] **Step 4: Verify** build + launch: select working/leave/holiday/weekend days; add/edit/delete updates; ⌘+Enter; private note persists; collapse ↔ expand animates and the collapsed strip shows the vertical date. Confirm board previews update live after adding updates.
- [ ] **Step 5: Commit**

```bash
git add SprintBuddy/Views/Detail/ SprintBuddy/ContentView.swift
git commit -m "Add collapsible day detail pane with updates, notes, off-states"
```

---

## Task 13: Settings + Help popovers, theme & view prefs

**Files:**
- Create: `SprintBuddy/Views/Sidebar/SettingsPopover.swift`
- Create: `SprintBuddy/Views/Sidebar/HelpPopover.swift`
- Modify: `SprintBuddy/Views/Sidebar/SidebarView.swift`

**Interfaces:**
- Consumes: `AppState` prefs, export/import handlers (passed as closures; implemented in Task 14).
- `SettingsPopover`: Appearance segmented control (Auto/Light/Dark → `appState.themeRaw`); View options — "Show weekends" `SBToggle` (`showWeekends`), "Flag unlogged days" `SBToggle` (`highlightUnlogged`); Data — Export / Import buttons (closures); inline import error text when present; footer "ScrumBuddy · v2.4.0".
- `HelpPopover`: "Quick tips" list of the three numbered tips (copy from prototype lines 194-196).
- Wire in `SidebarView` footer via `.popover(isPresented:)`.

- [ ] **Step 1: Implement SettingsPopover + HelpPopover.**
- [ ] **Step 2: Wire popovers + bindings** in the sidebar footer.
- [ ] **Step 3: Verify** build + launch: toggle theme (window recolors light/dark/auto), toggle Show weekends (grid adds/removes weekend cells), toggle Flag unlogged (past empty working days gain the dashed-warn "Not logged" state). Help shows tips.
- [ ] **Step 4: Commit**

```bash
git add SprintBuddy/Views/Sidebar/SettingsPopover.swift SprintBuddy/Views/Sidebar/HelpPopover.swift SprintBuddy/Views/Sidebar/SidebarView.swift
git commit -m "Add settings/help popovers with theme and view preferences"
```

---

## Task 14: Export / Import + Standup Notes + Delete + Import warning

**Files:**
- Create: `SprintBuddy/Views/Modals/StandupNotesSheet.swift`
- Create: `SprintBuddy/Views/Modals/DeleteSprintSheet.swift`
- Create: `SprintBuddy/Views/Modals/ImportWarningSheet.swift`
- Create: `SprintBuddy/SprintBuddy.entitlements`
- Modify: `SprintBuddy.xcodeproj/project.pbxproj` (entitlement + read-write files)
- Modify: `SprintBuddy/ContentView.swift` (wire handlers/sheets)

**Interfaces:**
- Consumes: `SprintStore`, `ScrumBuddyCodec`, `StandupFormatter`, `AppState`, `ModelContext`.
- Export: `NSSavePanel` (suggested `scrumbuddy-<today>.json`), write `SprintStore.exportData(sprints)`.
- Import: `NSOpenPanel` (`.json`), read → `ScrumBuddyCodec.decode`; on `.failure` set `appState.importError` (auto-clear after 4s); on `.success` if sprints exist set `pendingImport` + open `ImportWarningSheet`, else `SprintStore.replaceAll` immediately and reselect.
- `StandupNotesSheet`: read-only monospaced `TextEditor` of `StandupFormatter.text(activeDTO)`, Close + Copy (writes `NSPasteboard`, label flips to "Copied" for 2s). Width ~560.
- `DeleteSprintSheet`: confirm text naming the sprint; Cancel / Delete Sprint (error). On confirm delete model, reselect first remaining sprint (or none).
- `ImportWarningSheet`: "Replace all data?" with current vs pending counts; Cancel / Replace & Import → `replaceAll(pendingImport)`.
- Entitlements file:
  ```xml
  <?xml version="1.0" encoding="UTF-8"?>
  <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
  <plist version="1.0"><dict>
    <key>com.apple.security.app-sandbox</key><true/>
    <key>com.apple.security.files.user-selected.read-write</key><true/>
  </dict></plist>
  ```

- [ ] **Step 1: Flip file access to read-write.** In `project.pbxproj`, for **both** app-target Debug (line ~260) and Release (~292) configs: change `ENABLE_USER_SELECTED_FILES = readonly;` → `readwrite;` and add `CODE_SIGN_ENTITLEMENTS = SprintBuddy/SprintBuddy.entitlements;`. Create the entitlements file above.
- [ ] **Step 2: Verify project still builds** after the pbxproj edit: `xcodebuild ... build` → `** BUILD SUCCEEDED **`. (If the project fails to open, revert the edit and re-apply carefully — the two keys are plain string settings.)
- [ ] **Step 3: Implement the three sheets** per Interfaces.
- [ ] **Step 4: Implement export/import handlers** in ContentView and pass them into `SettingsPopover`; wire Standup/Delete from `OverviewCard`.
- [ ] **Step 5: Verify** build + launch: Standup Notes shows formatted text and Copy works; Export writes a JSON file (open it, confirm schema 5 + sprints); Import a good file replaces after warning; Import a garbage file shows the inline error; Delete removes the sprint and reselects.
- [ ] **Step 6: Commit**

```bash
git add SprintBuddy/Views/Modals/ SprintBuddy/SprintBuddy.entitlements SprintBuddy.xcodeproj/project.pbxproj SprintBuddy/ContentView.swift
git commit -m "Add export/import, standup notes, delete and import-warning modals"
```

---

## Task 15: Full-parity polish pass & final verification

**Files:** any view files needing adjustment.

- [ ] **Step 1: Side-by-side check** against `design_handoff/project/ScrumBuddy.dc.html` for each region in **both** light and dark: sidebar, overview card, every day-cell variant, detail pane (working + each off-state), collapsed strip, all four modals, both popovers, empty state. Note pixel/color deltas.
- [ ] **Step 2: Fix deltas** (spacing, radii, colors, fonts, hover/selected emphasis, animations `sbFadeIn`/`sbSlideIn`/`sbPop`).
- [ ] **Step 3: Re-run all logic tests** — recompile each `tests/logic/*Tests.swift` runner; expect `ALL PASS`.
- [ ] **Step 4: Final build + launch**: exercise create → log updates → change statuses → toggle prefs → export → delete. Confirm persistence across relaunch (SwiftData + `UserDefaults` UI state).
- [ ] **Step 5: Commit**

```bash
git add -A
git commit -m "Polish pass: pixel/behavior parity with prototype"
```

---

## Self-Review Notes

- **Spec coverage:** window/3-region layout (T8–T12), SwiftData model (T6), prefs/UI state (T8,T13), export/import schema (T5,T14), standup notes (T4,T14), styling tokens (T7), empty state/no-seed (T8), full-parity feature set (T9–T14), out-of-scope items respected (no fake traffic lights, no prev/next arrows, no bundled fonts). ✔
- **Type consistency:** `SprintDTO`/`DayDTO`/`UpdateDTO`, `DayStatus`/`UpdateType`, `SprintMath.*`, `ScrumBuddyCodec.decode -> Result`, `Sprint.toDTO()/from(_:)`, `SprintStore.createSprint/replaceAll/exportData` are used consistently across tasks. ✔
- **No placeholders:** logic tasks carry full code + real tests; UI tasks carry exact measurements and cite prototype line ranges for verbatim style values (the handoff is committed in-repo). ✔
