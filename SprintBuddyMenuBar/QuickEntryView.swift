//
//  QuickEntryView.swift
//  SprintBuddyMenuBar
//
//  The menu-bar quick-logger panel (agent). Logs a Done/Doing/Blocker update
//  for today into the shared App-Group store, shows a "Recent" recap, and hosts
//  the opt-in daily-recap control (the agent owns the notification permission).
//

import SwiftUI
import SwiftData
import SprintBuddyKit
import AppKit

struct QuickEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.colorScheme) private var colorScheme
    @Query(sort: \Sprint.createdAt, order: .reverse) private var sprints: [Sprint]

    @State private var draftText: String = ""
    @State private var draftType: UpdateType = .done
    @State private var justSaved = false
    @State private var savedResetTask: Task<Void, Never>?
    @State private var typeMenuOpen = false
    @State private var typeMenuHeight: CGFloat = 120

    @State private var recapEnabled = AppGroup.defaults.bool(forKey: PrefKey.recapEnabled)
    @State private var recapExpanded = AppGroup.defaults.bool(forKey: PrefKey.recapEnabled)
    // Re-read on each panel open so a theme change in the main app is reflected
    // (a separate process gets no live UserDefaults notification).
    @State private var themeRaw = AppGroup.defaults.string(forKey: PrefKey.theme) ?? "auto"

    private var todayISO: String { DateKey.iso(DateKey.today()) }

    private var dtos: [SprintDTO] { sprints.map { $0.toDTO() } }

    /// The sprint that covers today (most recently created wins) and today's `Day`.
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

    /// The most recent day *before today* that has updates.
    private var recentRecap: StandupRecap.DayRecap? {
        let yesterday = DateKey.iso(DateKey.addDays(DateKey.today(), -1))
        return StandupRecap.mostRecentLogged(dtos, onOrBefore: yesterday)
    }

    // MARK: - Theme (honor the shared "theme" pref; fall back to system for "auto")

    private var effectiveScheme: ColorScheme {
        switch themeRaw {
        case "dark": return .dark
        case "light": return .light
        default: return colorScheme
        }
    }
    private var palette: SBPalette { SBPalette(effectiveScheme) }

    // MARK: - Recap prefs bindings

    private var recapToggle: Binding<Bool> {
        Binding(
            get: { recapEnabled },
            set: { newValue in
                if newValue {
                    Task {
                        let granted = await RecapNotifier.requestAuthorization()
                        recapEnabled = granted
                        AppGroup.defaults.set(granted, forKey: PrefKey.recapEnabled)
                        if granted { RecapNotifier.refresh(sprints: dtos) }
                    }
                } else {
                    recapEnabled = false
                    AppGroup.defaults.set(false, forKey: PrefKey.recapEnabled)
                    RecapNotifier.cancel()
                }
            }
        )
    }

    private var recapTime: Binding<Date> {
        Binding(
            get: {
                var c = DateComponents()
                c.hour = (AppGroup.defaults.object(forKey: PrefKey.recapHour) as? Int) ?? 10
                c.minute = (AppGroup.defaults.object(forKey: PrefKey.recapMinute) as? Int) ?? 0
                return Calendar.current.date(from: c) ?? Date()
            },
            set: { newDate in
                let c = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                AppGroup.defaults.set(c.hour ?? 10, forKey: PrefKey.recapHour)
                AppGroup.defaults.set(c.minute ?? 0, forKey: PrefKey.recapMinute)
                RecapNotifier.refresh(sprints: dtos)
            }
        )
    }

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

            if let recap = recentRecap {
                Divider().overlay(p.border)
                recapSection(p, recap)
            }

            Divider().overlay(p.border)
            recapSettings(p)

            Divider().overlay(p.border)
            quitRow(p)
        }
        .frame(width: 320)
        .background(p.white)
        .overlayPreferenceValue(TypeAnchorKey.self) { anchor in
            GeometryReader { proxy in
                if typeMenuOpen, let anchor {
                    let rect = proxy[anchor]
                    ZStack(alignment: .topLeading) {
                        Color.white.opacity(0.001)
                            .contentShape(Rectangle())
                            .onTapGesture { typeMenuOpen = false }
                        typeMenuContent(p)
                            .fixedSize()
                            .onGeometryChange(for: CGFloat.self, of: { $0.size.height }, action: { typeMenuHeight = $0 })
                            // Open upward: the chip sits low in the panel, so a
                            // downward menu would be clipped by the window's bottom.
                            .offset(x: rect.minX, y: max(0, rect.minY - typeMenuHeight - 6))
                    }
                }
            }
        }
        .environment(\.palette, p)
        .preferredColorScheme(themeRaw == "auto" ? nil : effectiveScheme)
        .onAppear {
            themeRaw = AppGroup.defaults.string(forKey: PrefKey.theme) ?? "auto"
            recapEnabled = AppGroup.defaults.bool(forKey: PrefKey.recapEnabled)
        }
        .onDisappear { savedResetTask?.cancel() }
    }

    // MARK: - Header

    private func header(_ p: SBPalette) -> some View {
        let d = DateKey.parse(todayISO)
        return HStack(spacing: 10) {
            Image("BrandIcon")
                .resizable()
                .interpolation(.high)
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

            HStack(spacing: 8) {
                typeChip(p)
                Spacer(minLength: 0)
                saveButton(p)
            }
        }
        .padding(16)
    }

    /// The type chip (colored pill) that toggles the in-window dropdown, mirroring
    /// the day-detail status chip. Publishes its bounds so the dropdown anchors to it.
    private func typeChip(_ p: SBPalette) -> some View {
        let color = UpdateMeta.color(draftType, p)
        return Button {
            withAnimation(.easeInOut(duration: 0.15)) { typeMenuOpen.toggle() }
        } label: {
            HStack(spacing: 5) {
                Circle().fill(color).frame(width: 7, height: 7)
                Text(UpdateMeta.label(draftType))
                    .font(.system(size: 12.5, weight: .semibold))
                    .foregroundStyle(color)
                Image(systemName: "chevron.down")
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(color.opacity(0.7))
            }
            .padding(.vertical, 6)
            .padding(.horizontal, 10)
            .background(UpdateMeta.tint(draftType, p))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(color, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .anchorPreference(key: TypeAnchorKey.self, value: .bounds) { $0 }
    }

    /// The dropdown list (dot + label + checkmark), with its own card chrome.
    private func typeMenuContent(_ p: SBPalette) -> some View {
        VStack(spacing: 2) {
            ForEach([UpdateType.done, .doing, .blocker], id: \.self) { t in
                Button {
                    draftType = t
                    typeMenuOpen = false
                } label: {
                    HStack(spacing: 9) {
                        Circle().fill(UpdateMeta.color(t, p)).frame(width: 7, height: 7)
                        Text(UpdateMeta.label(t))
                            .font(.system(size: 13))
                            .foregroundStyle(p.textNavy)
                        Spacer(minLength: 0)
                        if draftType == t {
                            Image(systemName: "checkmark")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundStyle(p.blue)
                        }
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 10)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(6)
        .frame(width: 150)
        .background(p.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(p.border2, lineWidth: 1))
        .shadow(color: Color.rgba(19, 19, 76, 0.28), radius: 16, x: 0, y: 8)
    }

    private func saveButton(_ p: SBPalette) -> some View {
        Button(action: save) {
            HStack(spacing: 5) {
                Image(systemName: justSaved ? "checkmark" : "plus")
                    .font(.system(size: 11, weight: .semibold))
                Text(justSaved ? "Saved" : "Save")
                    .font(.system(size: 12.5, weight: .semibold))
                    .lineLimit(1)
                    .fixedSize()
            }
            .foregroundStyle(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 18)
            .background(justSaved ? p.success : p.blue)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
        .opacity(canSave ? 1 : 0.55)
    }

    // MARK: - Recent recap

    private func recapSection(_ p: SBPalette, _ recap: StandupRecap.DayRecap) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 7) {
                Text("RECENT")
                    .font(.system(size: 11, weight: .bold))
                    .tracking(0.4)
                    .foregroundStyle(p.grey2)
                Text(SprintMath.fmt(DateKey.parse(recap.dateISO)))
                    .font(.system(size: 11))
                    .foregroundStyle(p.grey3)
                Spacer(minLength: 0)
            }
            ForEach(Array(recap.updates.prefix(3).enumerated()), id: \.offset) { _, u in
                HStack(alignment: .top, spacing: 6) {
                    Circle()
                        .fill(UpdateMeta.color(u.type, p))
                        .frame(width: 6, height: 6)
                        .padding(.top, 5)
                    Text(u.text)
                        .font(.system(size: 12))
                        .foregroundStyle(p.textNavy)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if recap.updates.count > 3 {
                Text("+\(recap.updates.count - 3) more")
                    .font(.system(size: 11))
                    .foregroundStyle(p.grey3)
                    .padding(.leading, 12)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
    }

    // MARK: - Recap settings

    private func recapSettings(_ p: SBPalette) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) { recapExpanded.toggle() }
            } label: {
                HStack(spacing: 7) {
                    Text("DAILY RECAP")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.4)
                        .foregroundStyle(p.grey2)
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(p.grey3)
                        .rotationEffect(.degrees(recapExpanded ? 0 : -90))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if recapExpanded {
                HStack(spacing: 0) {
                    Text("Remind me daily")
                        .font(.system(size: 12.5))
                        .foregroundStyle(p.textNavy)
                    Spacer(minLength: 8)
                    SBToggle(isOn: recapToggle)
                }
                if recapEnabled {
                    HStack(spacing: 0) {
                        Text("at")
                            .font(.system(size: 12))
                            .foregroundStyle(p.grey2)
                        Spacer(minLength: 8)
                        DatePicker("", selection: recapTime, displayedComponents: .hourAndMinute)
                            .datePickerStyle(.field)
                            .labelsHidden()
                            .font(.system(size: 12))
                            .fixedSize()
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func quitRow(_ p: SBPalette) -> some View {
        Button { NSApp.terminate(nil) } label: {
            HStack(spacing: 6) {
                Image(systemName: "power")
                    .font(.system(size: 11, weight: .semibold))
                Text("Quit SprintBuddy")
                    .font(.system(size: 12.5, weight: .medium))
                Spacer(minLength: 0)
            }
            .foregroundStyle(p.grey1)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
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
            Text("Create a sprint that includes today, then log from here.")
                .font(.system(size: 11.5))
                .foregroundStyle(p.grey2)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Button(action: openMainApp) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.forward.app")
                        .font(.system(size: 11, weight: .semibold))
                    Text("Open SprintBuddy")
                        .font(.system(size: 12.5, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.vertical, 7)
                .padding(.horizontal, 14)
                .background(p.blue)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 4)
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
        SprintStore.save(modelContext)
        RecapNotifier.refresh(sprints: dtos)
        draftText = ""
        justSaved = true
        savedResetTask?.cancel()
        savedResetTask = Task {
            try? await Task.sleep(for: .seconds(1.6))
            if !Task.isCancelled { justSaved = false }
        }
    }
}

// MARK: - Anchor for positioning the type dropdown under its chip

private struct TypeAnchorKey: PreferenceKey {
    static let defaultValue: Anchor<CGRect>? = nil
    static func reduce(value: inout Anchor<CGRect>?, nextValue: () -> Anchor<CGRect>?) {
        value = nextValue() ?? value
    }
}
