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
            DatePicker("", selection: $startDate, displayedComponents: [.date])
                .datePickerStyle(.field)
                .labelsHidden()
                .font(.system(size: 13))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 7)
                .padding(.horizontal, 11)
                .background(palette.inputSoft)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                        .strokeBorder(palette.border2, lineWidth: 1)
                )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var durationField: some View {
        VStack(alignment: .leading, spacing: 6) {
            fieldLabel("Duration", required: false)
            Picker("", selection: $weeks) {
                ForEach(Self.weekOptions, id: \.self) { w in
                    Text(w == 1 ? "1 week" : "\(w) weeks").tag(w)
                }
            }
            .labelsHidden()
            .pickerStyle(.menu)
            .buttonStyle(.borderless)
            .font(.system(size: 13))
            .tint(palette.textNavy)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 6)
            .padding(.horizontal, 9)
            .background(palette.inputSoft)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(palette.border2, lineWidth: 1)
            )
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
        let rows = [
            "Creates \(weeks * 7) day cards",
            "\(SprintMath.fmt(s)) \u{2013} \(SprintMath.fmt(end))",
            "Weekends are marked automatically",
        ]

        return VStack(alignment: .leading, spacing: 5) {
            ForEach(rows, id: \.self) { row in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Circle()
                        .fill(palette.blue)
                        .frame(width: 4, height: 4)
                        .offset(y: -2)
                    Text(row)
                        .font(.system(size: 12))
                        .foregroundStyle(palette.grey2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, 11)
        .padding(.horizontal, 12)
        .background(palette.blueTint)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
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

#Preview {
    NewSprintSheet(isPresented: .constant(true)) { name, focus, startISO, weeks in
        print("create", name, focus, startISO, weeks)
    }
    .environment(\.palette, SBPalette(.light))
}
