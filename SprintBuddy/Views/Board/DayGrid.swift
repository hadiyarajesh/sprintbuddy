//
//  DayGrid.swift
//  SprintBuddy
//
//  The board's 5-column day grid. Transcribed from
//  design_handoff/project/ScrumBuddy.dc.html lines 251-295 (the `sc-for`
//  over `cells`) — iterates `SprintMath.visibleDates` and renders a
//  `DayCell` per date, computing the `notLogged` flag per `buildCells`
//  (lines 902-978): `highlightUnlogged && working && isPast && !logged && !isToday`.
//

import SwiftUI
import SprintBuddyKit

struct DayGrid: View {
    let dto: SprintDTO
    let today: String
    @ObservedObject var appState: AppState

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 16), count: 5)

    /// A double-click's first click always runs `onSelect` before `onOpen`
    /// fires, so `onSelect` records whether this day's pane was already open —
    /// letting the second click close it (double-click toggles the pane).
    @State private var doubleClickCloses = false

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(SprintMath.visibleDates(dto, showWeekends: appState.showWeekends), id: \.self) { iso in
                if let day = dto.days[iso] {
                    DayCell(
                        day: day,
                        isoDate: iso,
                        isToday: iso == today,
                        isSelected: iso == appState.selectedDateISO,
                        notLogged: isNotLogged(day, iso),
                        onSelect: {
                            doubleClickCloses = !appState.paneCollapsed && appState.selectedDateISO == iso
                            appState.selectedDateISO = iso
                            // Only auto-expand the detail pane when the pref is on;
                            // otherwise the user opens it via the collapsed strip.
                            if appState.autoOpenDetail { appState.paneCollapsed = false }
                        },
                        onOpen: {
                            appState.selectedDateISO = iso
                            appState.paneCollapsed = doubleClickCloses
                        }
                    )
                }
            }
        }
    }

    private func isNotLogged(_ day: DayDTO, _ iso: String) -> Bool {
        guard appState.highlightUnlogged, day.status == .working, iso < today else { return false }
        return day.updates.isEmpty
    }
}

#Preview {
    let dto = SprintDTO(
        id: "s1", name: "Sprint", start: "2026-07-06", weeks: 1,
        days: [
            "2026-07-06": DayDTO(status: .working, updates: [UpdateDTO(id: "1", type: .done, text: "Did a thing")]),
            "2026-07-07": DayDTO(status: .working),
            "2026-07-08": DayDTO(status: .leave),
            "2026-07-09": DayDTO(status: .working),
            "2026-07-10": DayDTO(status: .holiday),
            "2026-07-11": DayDTO(status: .weekend),
            "2026-07-12": DayDTO(status: .weekend),
        ]
    )
    return DayGrid(dto: dto, today: "2026-07-09", appState: AppState())
        .padding()
        .environment(\.palette, SBPalette(.light))
}
