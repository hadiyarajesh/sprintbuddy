//
//  QuickEntryView.swift
//  SprintBuddy
//
//  The menu-bar quick-logger panel. Lets you jot a Done/Doing/Blocker update
//  for *today* without opening the main window — it writes straight into the
//  same SwiftData store, so the entry shows up on the board immediately.
//
//  Presented by the `MenuBarExtra` scene in SprintBuddyApp (window style).
//

import SwiftUI
import SwiftData
import AppKit

struct QuickEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Sprint.createdAt, order: .reverse) private var sprints: [Sprint]

    @State private var draftText: String = ""
    @State private var draftType: UpdateType = .done
    @State private var justSaved = false
    @State private var savedResetTask: Task<Void, Never>?

    private var todayISO: String { DateKey.iso(DateKey.today()) }

    /// The sprint that covers today (most recently created wins, since
    /// `sprints` is sorted newest-first) and today's `Day` within it.
    private var target: (sprint: Sprint, day: Day)? {
        for sprint in sprints {
            if let day = sprint.days.first(where: { $0.dateISO == todayISO }) {
                return (sprint, day)
            }
        }
        return nil
    }

    private var canSave: Bool {
        target != nil && !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Theme

    /// Honor the app's chosen theme (stored by AppState under "theme"); fall
    /// back to the system scheme for "auto".
    private var themeRaw: String { UserDefaults.standard.string(forKey: "theme") ?? "auto" }
    private var effectiveScheme: ColorScheme {
        switch themeRaw {
        case "dark": return .dark
        case "light": return .light
        default: return colorScheme
        }
    }
    private var palette: SBPalette { SBPalette(effectiveScheme) }

    // MARK: - Body

    var body: some View {
        let p = palette
        VStack(alignment: .leading, spacing: 0) {
            header(p)
            Divider().overlay(p.border)
            if let target {
                composer(p, sprint: target.sprint, day: target.day)
            } else {
                emptyState(p)
            }
        }
        .frame(width: 320)
        .background(p.white)
        .environment(\.palette, p)
        .preferredColorScheme(themeRaw == "auto" ? nil : effectiveScheme)
        .onDisappear { savedResetTask?.cancel() }
    }

    // MARK: - Header

    private func header(_ p: SBPalette) -> some View {
        let d = DateKey.parse(todayISO)
        return HStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 26, height: 26)
            VStack(alignment: .leading, spacing: 1) {
                Text("Today")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(p.textNavy)
                Text(SprintMath.fmt(d))
                    .font(.system(size: 11))
                    .foregroundStyle(p.grey2)
            }
            Spacer(minLength: 0)
            if let target {
                Text("\(target.day.updates.count) logged")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(p.grey2)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 8)
                    .background(p.chip)
                    .clipShape(Capsule())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Composer

    private func composer(_ p: SBPalette, sprint: Sprint, day: Day) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(sprint.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(p.blue)
                .lineLimit(1)

            ZStack(alignment: .topLeading) {
                TextEditor(text: $draftText)
                    .font(.system(size: 13))
                    .foregroundStyle(p.textNavy)
                    .scrollContentBackground(.hidden)
                    .padding(6)
                    .onKeyPress(.return, phases: .down) { press in
                        guard press.modifiers.contains(.command) else { return .ignored }
                        save()
                        return .handled
                    }
                if draftText.isEmpty {
                    Text("What did you work on? (\u{2318} + Enter to save)")
                        .font(.system(size: 13))
                        .foregroundStyle(p.grey4)
                        .padding(.horizontal, 11)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }
            }
            .frame(height: 72)
            .background(p.inputSoft)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(p.grey6, lineWidth: 1)
            )

            HStack(spacing: 6) {
                ForEach([UpdateType.done, .doing, .blocker], id: \.self) { t in
                    TypeChipButton(type: t, isSelected: draftType == t, action: { draftType = t })
                }
                Spacer(minLength: 0)
                saveButton(p)
            }
        }
        .padding(16)
    }

    private func saveButton(_ p: SBPalette) -> some View {
        Button(action: save) {
            HStack(spacing: 5) {
                Image(systemName: justSaved ? "checkmark" : "plus")
                    .font(.system(size: 11, weight: .semibold))
                Text(justSaved ? "Saved" : "Save")
                    .font(.system(size: 12.5, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 7)
            .padding(.horizontal, 14)
            .background(justSaved ? p.success : p.blue)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.55)
    }

    // MARK: - Empty state (today isn't in any sprint)

    private func emptyState(_ p: SBPalette) -> some View {
        VStack(spacing: 8) {
            Image(systemName: "calendar.badge.exclamationmark")
                .font(.system(size: 26))
                .foregroundStyle(p.grey4)
            Text("No sprint covers today")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(p.textNavy)
            Text("Open SprintBuddy to create a sprint that includes today, then log from here.")
                .font(.system(size: 11.5))
                .foregroundStyle(p.grey2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.vertical, 22)
    }

    // MARK: - Save

    private func save() {
        guard let target, canSave else { return }
        let trimmed = draftText.trimmingCharacters(in: .whitespacesAndNewlines)
        let nextIndex = (target.day.updates.map(\.sortIndex).max() ?? -1) + 1
        target.day.updates.append(
            DayUpdate(id: UUID().uuidString, type: draftType, text: trimmed, sortIndex: nextIndex)
        )
        try? modelContext.save()
        draftText = ""
        justSaved = true
        savedResetTask?.cancel()
        savedResetTask = Task {
            try? await Task.sleep(for: .seconds(1.6))
            if !Task.isCancelled { justSaved = false }
        }
    }
}
