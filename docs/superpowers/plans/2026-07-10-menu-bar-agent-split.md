# SprintBuddy — Split into Main App + Menu-Bar Agent

Date: 2026-07-10
Status: Approved (approach)

## Goal

Make the menu-bar quick-logger (and its daily recap notifications) survive
independently of the main window app, so ⌘Q on the main app does **not** kill
the menu bar. Achieved by splitting into two processes that share one data
store.

## Target layout

Three targets in `SprintBuddy.xcodeproj`:

1. **SprintBuddyKit** (framework) — shared code both apps link:
   `Models/`, `Logic/`, `Persistence/`, `Storage/`, `Theme/`. Cross-module
   API becomes `public`.
2. **SprintBuddy** (existing main app) — the windowed UI (sidebar · board ·
   detail · modals). Dock icon. ⌘Q quits only this. **Drops** its
   `MenuBarExtra`.
3. **SprintBuddyMenuBar** (new agent app) — `LSUIElement` (no Dock icon),
   launches at login, resident. Hosts the `MenuBarExtra` quick-logger + the
   "Recent" recap, and is the **sole owner** of the daily recap notification.

## Data sharing

- App Group: `group.com.hadiyarajesh.sprintbuddy` on all three targets.
- SwiftData store moved into the App Group container:
  `ModelConfiguration(url: <appGroupContainer>/SprintBuddy.store)`.
- Both apps build their `ModelContainer` from that shared URL via a shared
  helper in SprintBuddyKit (`AppStore.container()`).
- Cross-process freshness: SwiftData isn't built for concurrent writers, but
  for a single user logging occasionally it's fine. Mitigations:
  - Only the **agent** schedules notifications (no duplicates).
  - Each process refreshes on activation (`NSApplication.didBecomeActiveNotification`)
    — re-query so the board/menu reflect the other side's writes.

## Launch at login

Repoint the "Launch at login" setting from the main app to the **agent**
(`SMAppService`), so the menu bar is present after reboot without opening the
main window. The main app can still register/unregister the agent from its
Settings toggle.

## Access-control changes (SprintBuddyKit → public)

Make `public` the symbols both apps use: `DateKey`, `DomainDTO`
(`SprintDTO`/`DayDTO`/`UpdateDTO`, `DayStatus`, `UpdateType`), `SprintMath`,
`StandupFormatter`, `StandupRecap`, `ScrumBuddyCodec`→`SprintBuddyCodec`,
`SprintStore`, the `@Model` types, `SBPalette`/`Radius`/`UpdateMeta`, the
shared `Components`, and the new `AppStore` container helper. `@Model` classes
and their initializers must be `public`.

## Execution order

**Phase A — you, in Xcode (I provide exact clicks):**
1. New framework target `SprintBuddyKit`.
2. New macOS App target `SprintBuddyMenuBar`, marked Agent (`LSUIElement`).
3. Add App Group `group.com.hadiyarajesh.sprintbuddy` to all three targets.
4. Link `SprintBuddyKit` into both app targets (Embed & Sign).

**Phase B — me, in code (after Phase A):**
5. Move shared sources into the `SprintBuddyKit` group; add `public`.
6. Add `AppStore.container()` (App Group URL) and point both apps at it.
7. Main app: delete its `MenuBarExtra`; `import SprintBuddyKit`.
8. Agent app: `@main` App with `MenuBarExtra` + `QuickEntryView` +
   `RecapNotifier`; `LSUIElement` Info.plist; `import SprintBuddyKit`.
9. Move `RecapNotifier` scheduling ownership to the agent; main app stops
   scheduling.
10. Launch-at-login → register the agent.
11. Cross-process refresh on `didBecomeActive`.

**Phase C — verify:** build both schemes; run main app + confirm ⌘Q quits it
while the agent's menu bar + notifications persist; log from the menu bar and
confirm it appears on the board after the main app refreshes.

## Risks

- Adding targets/framework is manual (Xcode UI) — no scripting here.
- SwiftData multi-process: acceptable for single-user; agent owns
  notifications; refresh-on-activate covers most staleness.
- Signing: three targets each need a signing identity/team (the existing dev
  team applies).
