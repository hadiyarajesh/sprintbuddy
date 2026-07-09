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

struct DayGrid: View {
    let dto: SprintDTO
    let today: String
    @ObservedObject var appState: AppState

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 5)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(SprintMath.visibleDates(dto, showWeekends: appState.showWeekends), id: \.self) { iso in
                if let day = dto.days[iso] {
                    DayCell(
                        day: day,
                        isoDate: iso,
                        isToday: iso == today,
                        isSelected: iso == appState.selectedDateISO,
                        notLogged: isNotLogged(day, iso),
                        onSelect: {
                            appState.selectedDateISO = iso
                            appState.paneCollapsed = false
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
