//
//  BoardView.swift
//  SprintBuddy
//
//  The board region for the active sprint: a scrollable column containing
//  the overview card and the day grid. Transcribed from
//  design_handoff/project/ScrumBuddy.dc.html lines 203-296 (the
//  `<main data-screen-label="Sprint Board">` `hasSprint` branch).
//
//  The active sprint's `SprintDTO` and today's ISO date are computed once
//  here and threaded down to `OverviewCard` / `DayGrid` to avoid repeated
//  `toDTO()` calls on every render.
//

import SwiftUI
import SwiftData

struct BoardView: View {
    let sprint: Sprint
    @ObservedObject var appState: AppState
    let onDelete: () -> Void
    let onStandup: () -> Void

    var body: some View {
        let dto = sprint.toDTO()
        let today = DateKey.iso(DateKey.today())

        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                OverviewCard(sprint: sprint, dto: dto, today: today, onDelete: onDelete, onStandup: onStandup)
                DayGrid(dto: dto, today: today, appState: appState)
            }
            .frame(maxWidth: 1000, alignment: .leading)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 26)
        .padding(.horizontal, 30)
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Sprint.self, Day.self, DayUpdate.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    let sprint = Sprint(id: "1", name: "Sprint 24 \u{2014} Checkout Revamp", focus: "Ship the new checkout flow", startISO: "2026-07-06", weeks: 1)
    let days: [(String, DayStatus, [DayUpdate])] = [
        ("2026-07-06", .working, [DayUpdate(id: "u1", type: .done, text: "Wired up the payment form", sortIndex: 0)]),
        ("2026-07-07", .working, []),
        ("2026-07-08", .working, []),
        ("2026-07-09", .leave, []),
        ("2026-07-10", .holiday, []),
        ("2026-07-11", .weekend, []),
        ("2026-07-12", .weekend, []),
    ]
    for (iso, status, updates) in days {
        let day = Day(dateISO: iso, status: status)
        day.updates = updates
        sprint.days.append(day)
    }
    context.insert(sprint)

    let appState = AppState()
    appState.selectedDateISO = "2026-07-08"

    return BoardView(sprint: sprint, appState: appState, onDelete: {}, onStandup: {})
        .frame(width: 1100, height: 800)
        .environment(\.palette, SBPalette(.light))
        .modelContainer(container)
}
