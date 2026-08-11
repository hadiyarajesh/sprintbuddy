//
//  NewSprintSheet.swift
//  SprintBuddy
//
//  The "New Sprint" modal: collects a name (required), optional focus, a
//  start date, and a duration in weeks, then hands the validated fields back
//  to the caller. Transcribed from design_handoff/project/ScrumBuddy.dc.html
//  lines 431-445 (the modal markup), the `createSprint` validation at lines
//  880-895, and the `formPreview` string built at lines 1064-1069.
//
//  Presented by ContentView via `.sheet(isPresented: $appState.newSprintOpen)`.
//  Form state lives in local `@State` here — SwiftUI builds a fresh instance
//  of this view each time the sheet is presented, so the fields always start
//  blank/default without any extra reset plumbing.
//

import SwiftUI
import SprintBuddyKit

struct NewSprintSheet: View {
    @Binding var isPresented: Bool
    let onCreate: (_ name: String, _ focus: String, _ startISO: String, _ weeks: Int) -> Void
    let saturdayIsWorkingDay: Bool

    @Environment(\.palette) private var palette

    @State private var name: String = ""
    @State private var focus: String = ""
    @State private var startDate: Date = DateKey.today()
    @State private var weeks: Int = 2
    @State private var nameError: String? = nil

    private static let weekOptions = [1, 2, 3, 4]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header

            nameField
            focusField

            HStack(alignment: .top, spacing: 12) {
                startDateField
                durationField
            }

            previewLine
            footer
        }
        .padding(24)
        .frame(width: 480)
        .background(palette.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    // MARK: - Header

    private var header: some View {
        Text("New Sprint")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(palette.textNavy)
    }

    // MARK: - Fields

    private var nameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Sprint name", required: true)
            textField("e.g. Sprint 24.15", text: $name, isError: nameError != nil)
                .onChange(of: name) { _, _ in nameError = nil }
            if let nameError {
                Text(nameError)
                    .font(.system(size: 11.5))
                    .foregroundStyle(palette.error)
            }
        }
    }

    private var focusField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Focus (optional)", required: false)
            textField("e.g. Backend API finalization and UI tweaks", text: $focus, isError: false)
        }
    }

    private var startDateField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Start date", required: true)
            SprintStartDatePicker(selection: $startDate)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var durationField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Duration", required: false)
            SprintDurationPicker(selection: $weeks, options: Self.weekOptions)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func fieldLabel(_ text: String, required: Bool) -> some View {
        HStack(spacing: 3) {
            Text(text)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(palette.grey1)
            if required {
                Text("*").foregroundStyle(palette.error)
            }
        }
    }

    private func textField(_ placeholder: String, text: Binding<String>, isError: Bool) -> some View {
        TextField(placeholder, text: text)
            .textFieldStyle(.plain)
            .font(.system(size: 13))
            .foregroundStyle(palette.ink)
            .padding(.vertical, 9)
            .padding(.horizontal, 11)
            .background(palette.inputSoft)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(isError ? palette.error : palette.border2, lineWidth: 1)
            )
    }

    // MARK: - Preview line (`formPreview`, lines 1064-1069)

    /// The start date normalized to its ISO day, mirroring the app's own
    /// persisted representation (`DateKey.iso`/`DateKey.parse` round-trip)
    /// so the preview always matches what `SprintMath.generateDays` builds.
    private var startISO: String { DateKey.iso(startDate) }

    private var previewLine: some View {
        let s = DateKey.parse(startISO)
        let end = DateKey.addDays(s, weeks * 7 - 1)
        return VStack(alignment: .leading, spacing: 13) {
            HStack(spacing: 10) {
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(palette.blue)
                    .frame(width: 32, height: 32)
                    .background(palette.white.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text("Sprint plan")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(palette.textNavy)
                    Text("\(SprintMath.fmt(s)) \u{2013} \(SprintMath.fmt(end))")
                        .font(.system(size: 11.5, weight: .medium))
                        .foregroundStyle(palette.grey2)
                }
                Spacer()
                Text(weeks == 1 ? "1 week" : "\(weeks) weeks")
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundStyle(palette.blue)
                    .padding(.vertical, 5)
                    .padding(.horizontal, 9)
                    .background(palette.white.opacity(0.7))
                    .clipShape(Capsule())
            }

            Divider().overlay(palette.blueTintBorder)

            HStack(spacing: 0) {
                planStat(value: "\(weeks * 7)", label: "day cards", icon: "rectangle.grid.1x2")
                Rectangle().fill(palette.blueTintBorder).frame(width: 1, height: 28)
                planStat(value: "\(weeks)", label: weeks == 1 ? "week" : "weeks", icon: "calendar")
                Rectangle().fill(palette.blueTintBorder).frame(width: 1, height: 28)
                planStat(
                    value: "\(weeks * (saturdayIsWorkingDay ? 6 : 5))",
                    label: "working days",
                    icon: "briefcase"
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(palette.blueTint)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(palette.blueTintBorder, lineWidth: 1)
        )
    }

    private func planStat(value: String, label: String, icon: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(palette.blue)
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(palette.textNavy)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(palette.grey2)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .padding(.horizontal, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 10) {
            Spacer()
            cancelButton
            createButton
        }
    }

    private var cancelButton: some View {
        Button {
            isPresented = false
        } label: {
            Text("Cancel")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(palette.ink)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .strokeBorder(palette.border2, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var createButton: some View {
        Button(action: submit) {
            Text("Create Sprint")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(palette.blue)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func submit() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            nameError = "Enter a sprint name"
            return
        }
        let trimmedFocus = focus.trimmingCharacters(in: .whitespacesAndNewlines)
        onCreate(trimmedName, trimmedFocus, startISO, weeks)
        isPresented = false
    }
}

private struct SprintDurationPicker: View {
    @Binding var selection: Int
    let options: [Int]

    @Environment(\.palette) private var palette

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { weeks in
                Button {
                    withAnimation(.easeInOut(duration: 0.16)) { selection = weeks }
                } label: {
                    Text("\(weeks)w")
                        .font(.system(size: 12.5, weight: .bold))
                        .foregroundStyle(selection == weeks ? Color.white : palette.grey2)
                        .frame(maxWidth: .infinity, minHeight: 32)
                        .background(selection == weeks ? palette.blue : Color.clear)
                        .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                }
                .buttonStyle(.plain)
                .help(weeks == 1 ? "1 week sprint" : "\(weeks) week sprint")
            }
        }
        .padding(2)
        .background(palette.inputSoft)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(palette.border2, lineWidth: 1)
        )
    }
}

#Preview {
    NewSprintSheet(isPresented: .constant(true), onCreate: { _, _, _, _ in }, saturdayIsWorkingDay: false)
    .environment(\.palette, SBPalette(.light))
}
