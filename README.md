# SprintBuddy

A native macOS app for logging your daily sprint effort. Create a sprint,
get a card for every day, and jot what you worked on — tagged **Done**,
**Doing**, or **Blocker** — then export tidy standup notes when you need them.

Built with SwiftUI + SwiftData for macOS.

## Features

- **Sprint board** — create a sprint of any length (1–4 weeks) and get a
  day card for every day, with weekends marked automatically.
- **Daily updates** — log what you worked on per day, tagged Done / Doing /
  Blocker, with inline edit and delete.
- **Day statuses** — mark a day as Working, Leave, Holiday, or Weekend;
  leave/holiday days are excluded from working-day totals.
- **Private notes** — per-day reminders that never appear on the board or in
  exports.
- **Progress at a glance** — logged / working-day count, progress bar, and
  leave/holiday tallies in the sprint overview.
- **Standup notes** — one-click formatted summary of the sprint, ready to
  copy into your standup.
- **JSON export / import** — back up or move your data; imports validate the
  file and confirm before replacing existing data.
- **Menu-bar quick logger** — a menu-bar panel to log today's update without
  opening the main window; stays available even when the window is closed.
- **Launch at login** — optional, via macOS `SMAppService`.
- **Light / dark / auto** appearance, plus "show weekends" and "flag
  unlogged days" view options.

## Download
Download the app from [Release](https://github.com/hadiyarajesh/sprintbuddy/releases/) page.

## Requirements

- macOS 26.5 or later
- Xcode 26 or later (Swift 5)

## Build & run

Open `SprintBuddy.xcodeproj` in Xcode and run the **SprintBuddy** scheme, or
from the command line:

```bash
xcodebuild -project SprintBuddy.xcodeproj -scheme SprintBuddy \
  -destination 'platform=macOS' build
```

## Architecture

- **Models / Logic** (`SprintBuddy/Models`, `SprintBuddy/Logic`,
  `SprintBuddy/Persistence/SprintBuddyCodec.swift`) — Foundation-only value
  types and pure functions (date math, sprint stats/status, standup
  formatting, JSON codec). These carry unit tests under `tests/logic/`,
  runnable with `swiftc`.
- **Storage** (`SprintBuddy/Storage`, `SprintBuddy/Persistence`) — SwiftData
  `@Model` types (`Sprint`, `Day`, `DayUpdate`) plus a store/bridge that maps
  to and from the Codable DTOs.
- **Views** (`SprintBuddy/Views`) — the three-region window (sidebar ·
  board · collapsible detail pane), the modals, and the menu-bar quick entry.
- **Theme** (`SprintBuddy/Theme`) — a `ColorScheme`-resolved palette and
  shared components.

## Tests

The pure logic layer is covered by standalone `swiftc` test runners:

```bash
swiftc -o /tmp/sb-codec \
  SprintBuddy/Models/DateKey.swift \
  SprintBuddy/Models/DomainDTO.swift \
  SprintBuddy/Logic/SprintMath.swift \
  SprintBuddy/Persistence/SprintBuddyCodec.swift \
  tests/logic/TestSupport.swift tests/logic/CodecTests.swift && /tmp/sb-codec
```

(Swap the last test file for `DateKeyTests.swift`, `DomainDTOTests.swift`,
`SprintMathTests.swift`, or `StandupFormatterTests.swift` to run the others.)
