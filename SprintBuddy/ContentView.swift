//
//  ContentView.swift
//  SprintBuddy
//
//  The app shell: a three-region layout (sidebar · board · detail) inside a
//  hidden-title-bar window. Sidebar content lands in Task 9, board content in
//  Task 10, and the detail pane in Task 12 — this task lays out the regions,
//  resolves the active sprint, injects the palette, and wires the empty state.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Sprint.createdAt, order: .reverse) private var sprints: [Sprint]
    @StateObject private var appState = AppState()
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

    var body: some View {
        let p = palette

        ZStack(alignment: .topLeading) {
            p.boardGradient
                .ignoresSafeArea()

            HStack(spacing: 0) {
                sidebarRegion(p)
                boardRegion(p)
                // Detail region: only shown once a sprint + day are selected (Task 12).
            }
        }
        .environment(\.palette, p)
        .preferredColorScheme(appState.colorSchemePreference)
        .frame(minWidth: 1180, minHeight: 720)
        .onChange(of: sprints.map(\.id), initial: true) { _, _ in
            syncSelection()
        }
        .sheet(isPresented: $appState.newSprintOpen) {
            newSprintStub
        }
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

    // MARK: - Regions

    private func sidebarRegion(_ p: SBPalette) -> some View {
        // Placeholder — real sidebar content (sprint lists, new-sprint button,
        // settings/help entry points) lands in Task 9.
        Rectangle()
            .fill(p.sidebar)
            .frame(width: 274)
            .overlay(alignment: .trailing) {
                Rectangle().fill(p.border).frame(width: 1)
            }
    }

    private func boardRegion(_ p: SBPalette) -> some View {
        Group {
            if activeSprint == nil {
                EmptyStateView(onNew: { appState.newSprintOpen = true })
            } else {
                // Placeholder — real board grid lands in Task 10.
                Text("Board")
                    .font(.system(size: 13))
                    .foregroundStyle(p.grey2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Sheet stub

    private var newSprintStub: some View {
        VStack(spacing: 16) {
            Text("New Sprint")
                .font(.system(size: 15, weight: .semibold))
            Button("Close") { appState.newSprintOpen = false }
        }
        .padding(24)
        .frame(width: 320, height: 180)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Sprint.self, Day.self, DayUpdate.self], inMemory: true)
}
