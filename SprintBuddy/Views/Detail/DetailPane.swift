//
//  DetailPane.swift
//  SprintBuddy
//
//  The expanded (388pt) right-hand detail pane for the selected day: a header
//  with the long date + status chip/menu and a floating collapse button, then
//  either the working-day composer/updates/private-note stack or an
//  `OffStateView` for leave/holiday/weekend days. Transcribed from
//  design_handoff/project/ScrumBuddy.dc.html lines 312-414, with the status
//  menu/chip and add/edit/delete logic from renderVals lines 980-1153.
//

import SwiftUI
import SwiftData

struct DetailPane: View {
    let sprint: Sprint
    @Bindable var day: Day
    @ObservedObject var appState: AppState

    @Environment(\.palette) private var palette
    @Environment(\.modelContext) private var modelContext

    @State private var draftText: String = ""
    @State private var draftType: UpdateType = .done

    // MARK: - Derived

    private var date: Date { DateKey.parse(day.dateISO) }
    private var isToday: Bool { day.dateISO == DateKey.iso(DateKey.today()) }
    /// The status menu only offers "Weekend" when the underlying calendar date
    /// actually falls on a Saturday/Sunday (statusMenu, line 983).
    private var isWeekendDate: Bool { DateKey.isWeekend(date) }

    private var dateLong: String {
        Self.longDate(day.dateISO)
    }

    /// Shared "<monthLong> <dayOfMonth>, <year>" formatting, also used by
    /// `ContentView.detailDateLong` for the `CollapsedStrip` label so both
    /// places render an identical string for the same day.
    static func longDate(_ iso: String) -> String {
        let d = DateKey.parse(iso)
        return "\(SprintMath.monthLong(d)) \(SprintMath.dayOfMonth(d)), \(Calendar.current.component(.year, from: d))"
    }

    private var sortedUpdates: [DayUpdate] {
        day.updates.sorted { $0.sortIndex < $1.sortIndex }
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            header
            ScrollView {
                Group {
                    if day.status == .working {
                        workingContent
                    } else {
                        OffStateView(status: day.status)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 4)
                .padding(.bottom, 20)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(width: 388)
        .frame(maxHeight: .infinity)
        .background(palette.white)
        .overlay(alignment: .leading) {
            Rectangle().fill(palette.border).frame(width: 1)
        }
        // In-window status dropdown: a transparent catcher dismisses it on an
        // outside tap; the menu is positioned just under the header chip.
        .overlay(alignment: .topTrailing) {
            if appState.statusMenuOpen {
                ZStack(alignment: .topTrailing) {
                    Color.white.opacity(0.001)
                        .contentShape(Rectangle())
                        .onTapGesture { appState.statusMenuOpen = false }
                    statusMenuContent
                        .padding(.top, 62)
                        .padding(.trailing, 24)
                }
            }
        }
        .overlay(alignment: .topLeading) {
            collapseButton
                .offset(x: -13, y: 28)
        }
        // Editing/drafting is per-day UI state; reset it whenever the selected day changes
        // so a leftover draft from a previous day never leaks into the new one.
        .onChange(of: day.dateISO) { _, _ in
            draftText = ""
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(dateLong)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(palette.textNavy)
                Text(isToday ? "Today" : SprintMath.weekdayLong(date))
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(isToday ? palette.blue : palette.grey3)
            }
            Spacer(minLength: 0)
            statusChipButton
        }
        .padding(.horizontal, 24)
        .padding(.top, 24)
        .padding(.bottom, 16)
    }

    // MARK: - Status chip + menu

    private struct StatusStyle {
        let label: String
        let color: Color
        let tint: Color
        let icon: String
    }

    private func statusStyle(_ status: DayStatus) -> StatusStyle {
        switch status {
        case .working:
            return StatusStyle(label: "Working", color: palette.blue, tint: palette.blueTint, icon: "pencil")
        case .leave:
            return StatusStyle(label: "Leave", color: palette.error, tint: palette.redTint, icon: "arrow.uturn.left")
        case .holiday:
            return StatusStyle(label: "Holiday", color: palette.warning, tint: palette.amberTint, icon: "calendar")
        case .weekend:
            return StatusStyle(label: "Weekend", color: palette.grey2, tint: palette.muted, icon: "clock")
        }
    }

    private var statusChipButton: some View {
        let s = statusStyle(day.status)
        return Button(action: { appState.statusMenuOpen.toggle() }) {
            HStack(spacing: 7) {
                Image(systemName: s.icon)
                    .font(.system(size: 11, weight: .semibold))
                Text(s.label)
                    .font(.system(size: 12.5, weight: .semibold))
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .opacity(0.7)
            }
            .foregroundStyle(s.color)
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(s.tint)
            .clipShape(Capsule())
            .overlay(
                Capsule().strokeBorder(s.color, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .help("Change day status")
    }

    /// The status dropdown, rendered as an in-window overlay (not a native
    /// popover) so it always stays within the app window. Carries its own
    /// card chrome since there's no popover frame around it.
    private var statusMenuContent: some View {
        VStack(spacing: 2) {
            statusMenuItem(.working, icon: "pencil", label: "Working", color: palette.blue)
            statusMenuItem(.leave, icon: "arrow.uturn.left", label: "Leave", color: palette.error)
            statusMenuItem(.holiday, icon: "calendar", label: "Holiday", color: palette.warning)
            if isWeekendDate {
                statusMenuItem(.weekend, icon: "clock", label: "Weekend", color: palette.grey3)
            }
        }
        .padding(6)
        .frame(width: 172)
        .background(palette.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(palette.border2, lineWidth: 1)
        )
        .shadow(color: Color.rgba(19, 19, 76, 0.28), radius: 16, x: 0, y: 8)
    }

    private func statusMenuItem(_ status: DayStatus, icon: String, label: String, color: Color) -> some View {
        Button {
            day.status = status
            appState.statusMenuOpen = false
        } label: {
            HStack(spacing: 9) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(color)
                Text(label)
                    .font(.system(size: 13))
                    .foregroundStyle(palette.textNavy)
                Spacer(minLength: 0)
                if day.status == status {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(palette.blue)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    // MARK: - Floating collapse button

    private var collapseButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.22)) {
                appState.paneCollapsed = true
            }
        } label: {
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(palette.grey1)
                .frame(width: 26, height: 26)
                .background(palette.white)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(palette.grey6, lineWidth: 1))
                .shadow(color: Color.rgba(19, 19, 76, 0.2), radius: 7, x: 0, y: 2)
        }
        .buttonStyle(.plain)
        .help("Collapse panel")
    }

    // MARK: - Working-day content

    private var workingContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            UpdateComposer(draftText: $draftText, draftType: $draftType, onAdd: addUpdate)
            updatesCard
            privateNoteSection
            savedRow
        }
    }

    private var updatesCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Text("UPDATES")
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(palette.grey2)
                Text("\(day.updates.count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(palette.grey2)
                    .padding(.vertical, 1)
                    .padding(.horizontal, 8)
                    .background(palette.chip)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 4)

            if sortedUpdates.isEmpty {
                Text("No updates yet \u{2014} add your first above")
                    .font(.system(size: 12.5))
                    .foregroundStyle(palette.grey3)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 8)
            } else {
                VStack(spacing: 6) {
                    ForEach(sortedUpdates, id: \.id) { update in
                        UpdateRow(update: update, onDelete: { deleteUpdate(update) })
                    }
                }
            }
        }
        .padding(12)
        .background(palette.inputSoft)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(palette.border, lineWidth: 1)
        )
    }

    private var privateNoteSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("Private note")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.textNavy)
                Image(systemName: "lock")
                    .font(.system(size: 11))
                    .foregroundStyle(palette.grey3)
                Text("only visible here")
                    .font(.system(size: 11))
                    .foregroundStyle(palette.grey3)
            }

            ZStack(alignment: .topLeading) {
                TextEditor(text: $day.privateNote)
                    .font(.system(size: 13))
                    .foregroundStyle(palette.textNavy)
                    .scrollContentBackground(.hidden)
                    .padding(6)

                if day.privateNote.isEmpty {
                    Text("Private reminders \u{2014} never shown on the board or in standup notes")
                        .font(.system(size: 13))
                        .foregroundStyle(palette.grey4)
                        .padding(.horizontal, 11)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 64)
            .background(palette.inputSoft)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(palette.grey6, lineWidth: 1)
            )
        }
    }

    private var savedRow: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal")
                .font(.system(size: 12))
                .foregroundStyle(palette.success)
            Text("Saved automatically")
                .font(.system(size: 11.5))
                .foregroundStyle(palette.grey3)
        }
    }

    // MARK: - Update mutations (addUpdate/onDelete, renderVals lines 1008-1017, 1117-1119)

    private func addUpdate() {
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let nextIndex = (day.updates.map(\.sortIndex).max() ?? -1) + 1
        day.updates.append(DayUpdate(id: UUID().uuidString, type: draftType, text: trimmed, sortIndex: nextIndex))
        try? modelContext.save()
        draftText = ""
    }

    private func deleteUpdate(_ update: DayUpdate) {
        day.updates.removeAll { $0.id == update.id }
        modelContext.delete(update)
        try? modelContext.save()
    }
}

#Preview("Working day") {
    let container = try! ModelContainer(
        for: Sprint.self, Day.self, DayUpdate.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    let sprint = Sprint(id: "1", name: "Sprint 24", focus: "Ship the checkout flow", startISO: "2026-07-06", weeks: 1)
    let day = Day(dateISO: "2026-07-09", status: .working, privateNote: "Remember to ping design about the empty state.")
    day.updates = [
        DayUpdate(id: "u1", type: .done, text: "Wired up the payment form", sortIndex: 0),
        DayUpdate(id: "u2", type: .blocker, text: "Waiting on API keys from platform team", sortIndex: 1),
    ]
    sprint.days.append(day)
    context.insert(sprint)

    return DetailPane(sprint: sprint, day: day, appState: AppState())
        .frame(height: 760)
        .environment(\.palette, SBPalette(.light))
        .modelContainer(container)
}

#Preview("Leave day") {
    let container = try! ModelContainer(
        for: Sprint.self, Day.self, DayUpdate.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = container.mainContext

    let sprint = Sprint(id: "1", name: "Sprint 24", focus: "Ship the checkout flow", startISO: "2026-07-06", weeks: 1)
    let day = Day(dateISO: "2026-07-10", status: .leave)
    sprint.days.append(day)
    context.insert(sprint)

    return DetailPane(sprint: sprint, day: day, appState: AppState())
        .frame(height: 760)
        .environment(\.palette, SBPalette(.light))
        .modelContainer(container)
}
