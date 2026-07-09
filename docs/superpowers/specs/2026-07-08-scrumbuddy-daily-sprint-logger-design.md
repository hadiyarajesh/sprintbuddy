# ScrumBuddy — Daily Sprint Logger (Design)

Date: 2026-07-08
Status: Approved

## Purpose

A native macOS app for logging daily sprint effort. Recreates the
`design_handoff/project/ScrumBuddy.dc.html` prototype as a SwiftUI + SwiftData
app, matching the mockup's visual design as closely as the platform allows.

The prototype is the source of truth (not the older `uploads/screen.png`
screenshot, which shows a superseded layout).

## Decisions

- **Scope:** full feature parity with the prototype.
- **Persistence:** SwiftData for the sprint data graph.
- **Fonts:** system SF Pro (no bundled Roboto/Inter).
- **Seed data:** none — first launch shows the empty state.
- **Deployment target:** macOS 26.5 (SwiftData + latest SwiftUI available).

## Window & Layout

Native macOS window with the title bar hidden and content extending into it
(`.windowStyle(.hiddenTitleBar)`), so the **real** macOS traffic lights sit over
the top of the sidebar. The mockup's drawn traffic lights are NOT recreated —
the sidebar brand header simply reserves vertical space to clear the native
control zone.

Three regions in a custom `HStack` — deliberately not `NavigationSplitView` or
`.inspector`, so the exact widths, the floating collapse button, and the
collapsed strip can be matched pixel-for-pixel:

1. **Left sidebar — 274px, always visible ("full pane"):**
   - Brand header (ScrumBuddy + version), clearing the traffic-light zone.
   - Scrollable Active / Archive sections, each a collapse toggle with a chevron
     and a count chip; rows show sprint name + date range, highlight when
     selected.
   - "New Sprint" secondary button.
   - Footer: Settings and Help buttons, each opening a popover.
2. **Center board — flexible width, min-width enforced, vertical scroll:**
   - Overview card: sprint name, status pill (Active/Completed/Upcoming),
     date range + "N-week sprint", "Day N of M" chip (active sprints only),
     editable focus field, progress bar, stat pills (logged / leave / holiday),
     and action buttons (Standup Notes, Delete).
   - 5-column day grid of day cells.
   - Empty state ("No sprints yet") when there is no active sprint.
3. **Right detail pane — 388px, collapsible:**
   - Day header (long date + weekday/Today) and a status menu button
     (Working / Leave / Holiday / Weekend; Weekend only offered on Sat/Sun).
   - Working days: add-update composer (textarea + Done/Doing/Blocker tag
     picker + Add, with ⌘/Ctrl+Enter shortcut), updates list (inline
     edit/delete, type tag), private note field, "Saved automatically" footer.
   - Non-working days (leave/holiday/weekend): centered "off" state with icon,
     title, and explanatory subtext.
   - Collapses to a 54px vertical-label strip via a floating circular button at
     the pane's leading edge; clicking the strip re-expands.

Navigation between sprints is via sidebar selection (the prototype's prev/next
arrows were removed in the final markup and are not implemented).

## Data Model (SwiftData)

- **Sprint**
  - `id: String`
  - `name: String`
  - `focus: String` (prototype's `description`)
  - `startDate: Date`
  - `weeks: Int`
  - `createdAt: Date`
  - `days: [Day]` (cascade delete)
  - Computed `status: SprintStatus` — `active`/`completed`/`upcoming` from the
    day range vs. today.
- **Day**
  - `date: Date` (day granularity; ISO string used for export keys)
  - `status: DayStatus` — `working`/`leave`/`holiday`/`weekend`
  - `privateNote: String`
  - `updates: [DayUpdate]` (cascade delete)
  - back-reference to `Sprint`
- **DayUpdate**
  - `id: String`
  - `type: UpdateType` — `done`/`doing`/`blocker`
  - `text: String`
  - `sortIndex: Int` (preserves entry order)

On sprint creation, generate `weeks × 7` Day rows starting at `startDate`,
auto-marking Saturday/Sunday as `weekend`.

Derived (computed, not stored): per-sprint stats (working / logged / leave /
holiday counts), progress percentage, date-range labels, cell previews,
"Day N of M".

## Preferences & UI State

`@AppStorage`-backed:

- `theme`: `auto`/`light`/`dark` → drives `.preferredColorScheme` (auto follows
  system appearance).
- `showWeekends`: Bool — include weekend cells in the board.
- `highlightUnlogged`: Bool — flag past working days with no updates.
- Persisted UI state mirroring the prototype: selected sprint id, selected
  date, detail-pane collapsed flag, Active/Archive section open flags.

## Export / Import

Codable DTOs map the SwiftData graph to/from the prototype's exact JSON schema:

```json
{
  "app": "ScrumBuddy",
  "schema": 5,
  "exportedAt": "<ISO8601>",
  "sprints": [
    {
      "id": "...", "name": "...", "description": "...",
      "start": "YYYY-MM-DD", "weeks": 2,
      "days": {
        "YYYY-MM-DD": {
          "status": "working|leave|holiday|weekend",
          "privateNote": "...",
          "updates": [ { "id": "...", "type": "done|doing|blocker", "text": "..." } ]
        }
      }
    }
  ]
}
```

- **Export:** `NSSavePanel`, suggested name `scrumbuddy-YYYY-MM-DD.json`.
- **Import:** `NSOpenPanel`; validate it looks like a ScrumBuddy export; if data
  already exists, show the "Replace all data?" warning modal before replacing
  the entire store. Invalid files surface an inline error in the Settings
  popover.
- **Standup Notes:** reuse the prototype's `exportText` formatting (name +
  range, focus, logged/leave/holiday summary, then per-day bulleted updates) in
  a modal with copy-to-clipboard.

## Styling

- A `Theme` tokens layer porting the mockup's CSS custom properties
  (`--sb-*` surface/border/tint tokens and `--pt-*` brand/semantic colors) for
  both light and dark, resolved against the active color scheme.
- System SF Pro throughout; sizes/weights mapped from the mockup.
- Modals presented as sheets; popovers via SwiftUI `.popover`.
- Custom components matching the mockup: status/stat pills, update type tags,
  the settings toggles, icon buttons.

## File Structure

```
SprintBuddy/
  SprintBuddyApp.swift        // App + SwiftData ModelContainer + window config
  Models/                     // Sprint, Day, DayUpdate, enums, computed helpers
  Persistence/                // Codable DTOs, export/import service
  Theme/                      // Color tokens, typography, reusable style helpers
  Views/
    ContentView.swift         // 3-region HStack + shared selection state
    Sidebar/                  // SidebarView, SprintRow, SettingsPopover, HelpPopover
    Board/                    // BoardView, OverviewCard, DayGrid, DayCell, EmptyState
    Detail/                   // DetailPane, UpdateComposer, UpdateRow, CollapsedStrip, OffStateView
    Modals/                   // NewSprint, StandupNotes, DeleteConfirm, ImportWarning
    Components/               // Pill, Tag, Toggle, IconButton
```

## Out of Scope

- Prototype's drawn traffic lights (native window provides real ones).
- Prev/next sprint navigation arrows (removed in the final prototype markup).
- Bundled web fonts.
- Multi-window / document-based architecture.
