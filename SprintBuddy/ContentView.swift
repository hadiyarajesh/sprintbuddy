//
//  ContentView.swift
//  SprintBuddy
//
//  The app shell: a three-region layout (sidebar · board · detail) inside a
//  hidden-title-bar window. Sidebar content landed in Task 9, board content
//  (BoardView) in Task 10, and the detail pane (DetailPane/CollapsedStrip)
//  landed in Task 12 — this file lays out the regions, resolves the active
//  sprint + selected day, injects the palette, and wires the empty state.
//

import SwiftUI
import SprintBuddyKit
import SwiftData
import AppKit
import UniformTypeIdentifiers

struct ContentView: View {
    @Query(sort: \Sprint.createdAt, order: .reverse) private var sprints: [Sprint]
    @ObservedObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.modelContext) private var modelContext

    private var palette: SBPalette { SBPalette(colorScheme) }

    /// The sprint matching `appState.selectedSprintID`, falling back to the
    /// most recently created sprint when there is no selection (or the
    /// selected sprint no longer exists).
    private var activeSprint: Sprint? {
        if let id = appState.selectedSprintID, let match = sprints.first(where: { $0.id == id }) {
            return match
        }
        return sprints.first
    }

    /// The `Day` matching `appState.selectedDateISO` within `sprint`, falling back to
    /// `SprintMath.defaultDate` (today if it exists in the sprint, else the first
    /// working day, else the sprint's first day) when there's no selection or the
    /// selected date isn't part of this sprint.
    private func selectedDay(in sprint: Sprint) -> Day? {
        if let iso = appState.selectedDateISO, let match = sprint.days.first(where: { $0.dateISO == iso }) {
            return match
        }
        let sortedDays = sprint.days.sorted { $0.dateISO < $1.dateISO }
        guard let defaultISO = SprintMath.defaultDate(sprint.toDTO(), today: DateKey.iso(DateKey.today())) else {
            return sortedDays.first
        }
        return sortedDays.first(where: { $0.dateISO == defaultISO }) ?? sortedDays.first
    }

    var body: some View {
        let p = palette

        ZStack(alignment: .topLeading) {
            p.boardGradient
                .ignoresSafeArea()

            HStack(spacing: 0) {
                sidebarRegion(p)
                boardRegion(p)
                detailRegion(p)
            }
        }
        .environment(\.palette, p)
        .preferredColorScheme(appState.colorSchemePreference)
        .frame(minWidth: 1180, minHeight: 720)
        .onChange(of: sprints.map(\.id), initial: true) { _, _ in
            syncSelection()
            applyWorkCalendarPreference()
        }
        .onChange(of: appState.saturdayIsWorkingDay, initial: true) { _, _ in
            applyWorkCalendarPreference()
        }
        .sheet(isPresented: $appState.newSprintOpen) {
            themed {
                NewSprintSheet(
                    isPresented: $appState.newSprintOpen,
                    onCreate: createSprint,
                    saturdayIsWorkingDay: appState.saturdayIsWorkingDay
                )
            }
        }
        .sheet(isPresented: $appState.standupOpen) {
            themed {
                StandupNotesSheet(
                    text: activeSprint.map { StandupFormatter.text($0.toDTO()) } ?? "",
                    onClose: { appState.standupOpen = false }
                )
            }
        }
        .sheet(isPresented: $appState.summaryOpen) {
            themed {
                if let sprint = activeSprint {
                    SprintSummarySheet(sprint: sprint.toDTO(), onClose: { appState.summaryOpen = false })
                }
            }
        }
        .sheet(isPresented: $appState.deleteOpen) {
            themed {
                DeleteSprintSheet(
                    sprintName: activeSprint?.name ?? "",
                    onCancel: { appState.deleteOpen = false },
                    onConfirm: confirmDelete
                )
            }
        }
        .sheet(isPresented: $appState.importWarnOpen) {
            themed {
                ImportWarningSheet(
                    currentCount: sprints.count,
                    pendingCount: appState.pendingImport?.count ?? 0,
                    pendingNames: appState.pendingImport?.map(\.name) ?? [],
                    onCancel: {
                        appState.pendingImport = nil
                        appState.importWarnOpen = false
                    },
                    onConfirm: { applyImport(appState.pendingImport ?? []) }
                )
            }
        }
    }

    /// Sheets present in a separate hosting context that doesn't inherit the
    /// window's `.preferredColorScheme` or the injected palette, so re-apply
    /// both to keep modals matching the app's theme.
    @ViewBuilder
    private func themed<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .environment(\.palette, palette)
            .preferredColorScheme(appState.colorSchemePreference)
    }

    /// Creates a sprint via `SprintStore`, persists it, and selects it (and
    /// its default day) so the board renders the new sprint immediately.
    private func createSprint(name: String, focus: String, startISO: String, weeks: Int) {
        let created = SprintStore.createSprint(
            name: name,
            focus: focus,
            startISO: startISO,
            weeks: weeks,
            saturdayIsWorkingDay: appState.saturdayIsWorkingDay,
            in: modelContext
        )
        SprintStore.save(modelContext)
        appState.selectedSprintID = created.id
        appState.selectedDateISO = SprintMath.defaultDate(created.toDTO(), today: DateKey.iso(DateKey.today()))
        appState.paneCollapsed = false
    }

    // MARK: - Export / Import / Delete

    /// Serializes all sprints to the export JSON and writes them to a
    /// user-chosen file via `NSSavePanel` (needs the read-write user-selected
    /// files entitlement enabled in Task 14A).
    private func exportData() {
        let data: Data
        do {
            data = try SprintStore.exportData(sprints)
        } catch {
            showImportError(String(localized: "Couldn’t prepare the export."))
            return
        }
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.json]
        panel.nameFieldStringValue = "sprintbuddy-\(DateKey.iso(DateKey.today())).json"
        guard panel.runModal() == .OK, let url = panel.url else { return }
        do {
            try data.write(to: url)
        } catch {
            showImportError(String(localized: "Couldn’t save the export."))
        }
    }

    /// Reads a user-chosen JSON file via `NSOpenPanel`, validates it through
    /// `SprintBuddyCodec`, and either applies it immediately (no existing data)
    /// or stages it behind the "Replace all data?" warning.
    private func importData() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.json]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        guard panel.runModal() == .OK, let url = panel.url else { return }
        guard let data = try? Data(contentsOf: url) else {
            showImportError(String(localized: "Couldn’t read that file."))
            return
        }
        switch SprintBuddyCodec.decode(data) {
        case .failure(.notJSON):
            showImportError(String(localized: "That file isn’t valid JSON."))
        case .failure(.notSprintBuddy):
            showImportError(String(localized: "This doesn’t look like a SprintBuddy export."))
        case .success(let dtos):
            if sprints.isEmpty {
                applyImport(dtos)
            } else {
                appState.pendingImport = dtos
                appState.importWarnOpen = true
                appState.importError = ""
            }
        }
    }

    /// Shows an inline import error in the Settings popover and clears it after
    /// ~4s (only if it hasn't been replaced by a newer message).
    private func showImportError(_ message: String) {
        appState.importError = message
        Task {
            try? await Task.sleep(for: .seconds(4))
            if appState.importError == message { appState.importError = "" }
        }
    }

    /// Replaces the entire store with the imported sprints, persists, and
    /// selects the first imported sprint (and its default day).
    private func applyImport(_ dtos: [SprintDTO]) {
        SprintStore.replaceAll(with: dtos, in: modelContext)
        SprintStore.save(modelContext)
        appState.selectedSprintID = dtos.first?.id
        appState.selectedDateISO = dtos.first.flatMap {
            SprintMath.defaultDate($0, today: DateKey.iso(DateKey.today()))
        }
        appState.paneCollapsed = false
        appState.pendingImport = nil
        appState.importWarnOpen = false
        appState.settingsOpen = false
    }

    /// Deletes the active sprint (cascading its days/updates) and reselects the
    /// next most-recently-created sprint, or clears the selection when none
    /// remain. Mirrors the prototype's `confirmDelete`.
    private func confirmDelete() {
        guard let sprint = activeSprint else {
            appState.deleteOpen = false
            return
        }
        let deletedID = sprint.id
        modelContext.delete(sprint)
        SprintStore.save(modelContext)
        let next = sprints
            .filter { $0.id != deletedID }
            .sorted { $0.createdAt > $1.createdAt }
            .first
        appState.selectedSprintID = next?.id
        appState.selectedDateISO = next.flatMap {
            SprintMath.defaultDate($0.toDTO(), today: DateKey.iso(DateKey.today()))
        }
        appState.paneCollapsed = false
        appState.deleteOpen = false
    }

    /// Keeps `appState.selectedSprintID` pointed at a real sprint: resolves to
    /// the currently active sprint (or `nil` when there are none) whenever the
    /// set of sprints changes.
    private func syncSelection() {
        let resolvedID = activeSprint?.id
        if appState.selectedSprintID != resolvedID {
            appState.selectedSprintID = resolvedID
        }
    }

    /// Keeps active sprint boards aligned with the preferred working calendar.
    /// A Saturday that already contains work stays visible when the preference
    /// is turned off, so a saved update is never hidden as an off day.
    private func applyWorkCalendarPreference() {
        let today = DateKey.iso(DateKey.today())
        var changed = false

        for sprint in sprints where SprintMath.status(sprint.toDTO(), today: today) != .completed {
            for day in sprint.days where DateKey.weekday(DateKey.parse(day.dateISO)) == 7 {
                if appState.saturdayIsWorkingDay, day.status == .weekend {
                    day.status = .working
                    changed = true
                } else if !appState.saturdayIsWorkingDay,
                          day.status == .working,
                          day.updates.isEmpty,
                          day.privateNote.isEmpty {
                    day.status = .weekend
                    changed = true
                }
            }
        }

        if changed { SprintStore.save(modelContext) }
    }

    // MARK: - Regions

    private func sidebarRegion(_ p: SBPalette) -> some View {
        // `p` is unused here — SidebarView reads the palette from the
        // environment (injected on the root `ZStack` above).
        SidebarView(
            sprints: sprints,
            appState: appState,
            onNewSprint: { appState.newSprintOpen = true },
            onExport: exportData,
            onImport: importData
        )
    }

    private func boardRegion(_ p: SBPalette) -> some View {
        Group {
            if let sprint = activeSprint {
                BoardView(
                    sprint: sprint,
                    appState: appState,
                    onDelete: { appState.deleteOpen = true },
                    onStandup: { appState.standupOpen = true },
                    onSummary: { appState.summaryOpen = true }
                )
            } else {
                EmptyStateView(onNew: { appState.newSprintOpen = true })
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// The right-hand detail region: only present when there is an active sprint AND a
    /// resolved selected day. Swaps between the 388pt `DetailPane` and the 54pt
    /// `CollapsedStrip` based on `appState.paneCollapsed`, animating the swap with a
    /// trailing-edge slide (approximating the prototype's `sbSlideIn`).
    @ViewBuilder
    private func detailRegion(_ p: SBPalette) -> some View {
        if let sprint = activeSprint, let day = selectedDay(in: sprint) {
            Group {
                if appState.paneCollapsed {
                    CollapsedStrip(dateLong: detailDateLong(day), onExpand: {
                        withAnimation(.easeInOut(duration: 0.22)) {
                            appState.paneCollapsed = false
                        }
                    })
                } else {
                    DetailPane(
                        sprint: sprint,
                        day: day,
                        appState: appState,
                        isReadOnly: SprintMath.status(sprint.toDTO(), today: DateKey.iso(DateKey.today())) == .completed
                    )
                }
            }
            .transition(.move(edge: .trailing))
            .animation(.easeInOut(duration: 0.22), value: appState.paneCollapsed)
        }
    }

    private func detailDateLong(_ day: Day) -> String {
        DetailPane.longDate(day.dateISO)
    }
}

#Preview {
    ContentView(appState: AppState())
        .modelContainer(for: [Sprint.self, Day.self, DayUpdate.self], inMemory: true)
}
