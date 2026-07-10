//
//  SettingsPopover.swift
//  SprintBuddy
//
//  The Settings popover attached to the sidebar footer's "Settings" button:
//  an Appearance segmented control (Auto/Light/Dark), two View options
//  toggles (Show weekends / Flag unlogged days), and a Data section with
//  Export/Import actions (closures — the actual file-panel logic lands in
//  Task 14) plus an inline import-error line.
//
//  Transcribed from design_handoff/project/ScrumBuddy.dc.html lines 156-187
//  (popover markup) and the `themeButtons`/toggle state builders around
//  lines 1198-1211.
//
//  Theme wiring: tapping a segment sets `appState.theme` directly (the
//  durable `@Published var theme: String` on `AppState`, mirrored to
//  UserDefaults — see AppState.swift's design note). Because `AppState` is
//  an `ObservableObject` and `theme` is `@Published`, that mutation fires
//  `objectWillChange`; `ContentView` observes `appState` via `@StateObject`
//  and reads `appState.colorSchemePreference` (derived from `theme`) into
//  `.preferredColorScheme(...)`, so the whole window re-renders in the new
//  scheme immediately — no extra plumbing needed here.
//
//  Similarly, the `SBToggle` bindings below mutate `appState.showWeekends`
//  / `appState.highlightUnlogged` in place; `BoardView`/`DayCell` already
//  read those same `@Published` properties off the shared `appState`
//  instance, so they re-render (grid gains/loses weekend cells, cells
//  gain/lose the dashed "not logged" warning) the moment either toggle
//  flips — again, no new wiring beyond binding to the existing properties.
//

import SwiftUI
import SprintBuddyKit

struct SettingsPopover: View {
    @ObservedObject var appState: AppState
    var onExport: () -> Void = {}
    var onImport: () -> Void = {}

    @Environment(\.palette) private var palette

    private static let themes: [(value: String, label: String)] = [
        ("auto", "Auto"),
        ("light", "Light"),
        ("dark", "Dark"),
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionLabel("Appearance")
                .padding(.bottom, 8)
            themeSegmented
                .padding(.bottom, 14)

            sectionLabel("View options")
                .padding(.bottom, 2)
            toggleRow(title: "Show weekends", isOn: $appState.showWeekends)
            toggleRow(title: "Flag unlogged days", isOn: $appState.highlightUnlogged)

            sectionLabel("Data")
                .padding(.top, 12)
                .padding(.bottom, 8)
            dataButtons

            if !appState.importError.isEmpty {
                Text(appState.importError)
                    .font(.system(size: 11.5))
                    .foregroundStyle(palette.error)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
            }

            footer
        }
        .padding(14)
        .frame(width: 252)
        .background(palette.white)
    }

    // MARK: - Section label

    private func sectionLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 12, weight: .bold))
            .tracking(0.6)
            .foregroundStyle(palette.grey2)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Appearance segmented control

    private var themeSegmented: some View {
        HStack(spacing: 3) {
            ForEach(Self.themes, id: \.value) { theme in
                themeButton(value: theme.value, label: theme.label)
            }
        }
        .padding(3)
        .background(palette.muted)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }

    private func themeButton(value: String, label: String) -> some View {
        let isActive = appState.theme == value
        return Button {
            appState.theme = value
        } label: {
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isActive ? palette.textNavy : palette.grey2)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .padding(.horizontal, 4)
                .background(isActive ? palette.white : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .shadow(color: isActive ? Color.black.opacity(0.14) : .clear, radius: 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    // MARK: - View options

    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 0) {
            Text(title)
                .font(.system(size: 13))
                .foregroundStyle(palette.textNavy)
            Spacer(minLength: 8)
            SBToggle(isOn: isOn)
        }
        .padding(.vertical, 7)
    }

    // MARK: - Data

    private var dataButtons: some View {
        HStack(spacing: 8) {
            DataActionButton(systemName: "square.and.arrow.up", label: "Export", action: onExport)
            DataActionButton(systemName: "square.and.arrow.down", label: "Import", action: onImport)
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(alignment: .leading, spacing: 0) {
            Rectangle()
                .fill(palette.muted)
                .frame(height: 1)
                .padding(.top, 10)
            Text("SprintBuddy · v2.4.0")
                .font(.system(size: 11))
                .foregroundStyle(palette.grey3)
                .padding(.top, 8)
        }
    }
}

// MARK: - DataActionButton

/// Outline icon+label button used for Export/Import, with a hover background
/// matching the prototype's `style-hover="background:var(--sb-hover)"`.
private struct DataActionButton: View {
    let systemName: String
    let label: String
    let action: () -> Void

    @Environment(\.palette) private var palette
    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: systemName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(palette.grey2)
                Text(label)
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(palette.textNavy)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(isHovering ? palette.hover : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(palette.grey6, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

#Preview {
    SettingsPopover(appState: AppState())
        .environment(\.palette, SBPalette(.light))
}
