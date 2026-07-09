//
//  SidebarView.swift
//  SprintBuddy
//
//  The app's fixed-width left sidebar: brand header, a scrollable Active /
//  Archive breakdown of sprints, a "New Sprint" action, and a Settings/Help
//  footer. Section open/close state and sprint selection live on `AppState`.
//
//  Transcribed from design_handoff/project/ScrumBuddy.dc.html lines ~77-201
//  (`<aside data-screen-label="Sidebar">`).
//
//  The Settings/Help footer buttons toggle `appState.settingsOpen` /
//  `helpOpen`, each driving a `.popover` (SettingsPopover / HelpPopover,
//  Task 13). `onExport`/`onImport` are optional closures forwarded to
//  `SettingsPopover`'s Data section — they default to no-ops here; Task 14
//  supplies the real NSSavePanel/NSOpenPanel-backed implementations from
//  `ContentView`.
//

import SwiftUI
import AppKit
import SwiftData

struct SidebarView: View {
    let sprints: [Sprint]
    @ObservedObject var appState: AppState
    let onNewSprint: () -> Void
    var onExport: () -> Void = {}
    var onImport: () -> Void = {}

    @Environment(\.palette) private var palette
    @State private var isHoveringNewSprint = false

    private var todayISO: String { DateKey.iso(DateKey.today()) }

    /// Sprints that are not yet completed (active or upcoming), newest start first.
    private var activeSprints: [Sprint] {
        sprints
            .filter { SprintMath.status($0.toDTO(), today: todayISO) != .completed }
            .sorted { $0.startISO > $1.startISO }
    }

    /// Completed sprints, newest start first.
    private var archiveSprints: [Sprint] {
        sprints
            .filter { SprintMath.status($0.toDTO(), today: todayISO) == .completed }
            .sorted { $0.startISO > $1.startISO }
    }

    var body: some View {
        VStack(spacing: 0) {
            brandRow
                .padding(.top, 28)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    section(title: "Active", sprints: activeSprints, isOpen: $appState.activeOpen, emptyText: "No active sprints")
                    section(title: "Archive", sprints: archiveSprints, isOpen: $appState.archiveOpen, emptyText: "No archived sprints")
                }
                .padding(.horizontal, 12)
                .padding(.top, 12)
                .padding(.bottom, 8)
            }

            newSprintButton
                .padding(.horizontal, 14)
                .padding(.top, 14)
                .padding(.bottom, 4)

            footer
        }
        .frame(width: 274)
        .frame(maxHeight: .infinity)
        .background(palette.sidebar)
        .overlay(alignment: .trailing) {
            Rectangle().fill(palette.border).frame(width: 1)
        }
    }

    // MARK: - Brand

    private var brandRow: some View {
        HStack(spacing: 11) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .interpolation(.high)
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .shadow(color: Color(hex: "2a76e1").opacity(0.3), radius: 7, x: 0, y: 3)

            VStack(alignment: .leading, spacing: 1) {
                Text("SprintBuddy")
                    .font(.system(size: 18, weight: .bold))
                    .tracking(-0.2)
                    .foregroundStyle(palette.blue)
                Text("v2.4.0")
                    .font(.system(size: 11))
                    .foregroundStyle(palette.grey3)
            }
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Sections

    @ViewBuilder
    private func section(title: String, sprints: [Sprint], isOpen: Binding<Bool>, emptyText: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            SectionHeaderButton(
                title: title,
                count: sprints.count,
                isExpanded: isOpen.wrappedValue,
                action: { withAnimation(.easeInOut(duration: 0.2)) { isOpen.wrappedValue.toggle() } }
            )

            if isOpen.wrappedValue {
                if sprints.isEmpty {
                    Text(emptyText)
                        .font(.system(size: 12))
                        .foregroundStyle(palette.grey4)
                        .padding(.horizontal, 12)
                        .padding(.top, 4)
                        .padding(.bottom, 10)
                } else {
                    VStack(spacing: 4) {
                        ForEach(sprints, id: \.id) { sprint in
                            SprintRow(
                                sprint: sprint,
                                isSelected: sprint.id == appState.selectedSprintID,
                                onSelect: { select(sprint) }
                            )
                        }
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 10)
                }
            }
        }
    }

    private func select(_ sprint: Sprint) {
        appState.selectedSprintID = sprint.id
        appState.selectedDateISO = SprintMath.defaultDate(sprint.toDTO(), today: todayISO)
        appState.paneCollapsed = false
    }

    // MARK: - New Sprint

    private var newSprintButton: some View {
        Button(action: onNewSprint) {
            HStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 12, weight: .semibold))
                Text("New Sprint")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(palette.blue.opacity(isHoveringNewSprint ? 0.9 : 1))
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .shadow(color: Color.rgba(42, 118, 225, 0.35), radius: 8, x: 0, y: 3)
        }
        .buttonStyle(.plain)
        .onHover { isHoveringNewSprint = $0 }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(alignment: .leading, spacing: 2) {
            SidebarFooterButton(systemName: "gearshape", title: "Settings") {
                appState.settingsOpen.toggle()
            }
            .popover(isPresented: $appState.settingsOpen, arrowEdge: .bottom) {
                SettingsPopover(appState: appState, onExport: onExport, onImport: onImport)
            }

            SidebarFooterButton(systemName: "questionmark.circle", title: "Help") {
                appState.helpOpen.toggle()
            }
            .popover(isPresented: $appState.helpOpen, arrowEdge: .bottom) {
                HelpPopover()
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 8)
        .padding(.bottom, 10)
        .overlay(alignment: .top) {
            Rectangle().fill(palette.border).frame(height: 1)
        }
    }
}

// MARK: - SidebarFooterButton

/// Footer action row (Settings / Help): icon + label, with a hover background.
private struct SidebarFooterButton: View {
    let systemName: String
    let title: String
    let action: () -> Void

    @Environment(\.palette) private var palette
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: systemName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.grey2)
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(palette.grey1)
                Spacer(minLength: 0)
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 10)
            .background(isHovering ? palette.hover : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

#Preview {
    SidebarView(sprints: [], appState: AppState(), onNewSprint: {})
        .environment(\.palette, SBPalette(.light))
        .frame(height: 700)
}
