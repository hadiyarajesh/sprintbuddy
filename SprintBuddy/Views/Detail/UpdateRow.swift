//
//  UpdateRow.swift
//  SprintBuddy
//
//  A single update entry inside the detail pane's "Updates" card. View mode
//  shows the type tag + text + edit/delete icon buttons; edit mode swaps in
//  a `TextEditor` + type chips + Cancel/Save, with editing state kept local
//  to the row (toggled by the pencil button). Transcribed from
//  design_handoff/project/ScrumBuddy.dc.html lines 361-385, with the
//  save/delete semantics from renderVals' onSaveEdit/onDelete (lines 1117-1119):
//  saving an emptied draft deletes the update instead of leaving a blank one.
//

import SwiftUI

struct UpdateRow: View {
    @Bindable var update: DayUpdate
    let onDelete: () -> Void

    @Environment(\.palette) private var palette
    @State private var isEditing = false
    @State private var editText: String = ""

    var body: some View {
        Group {
            if isEditing {
                editView
            } else {
                viewMode
            }
        }
        .padding(10)
        .background(palette.white)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(palette.cardBorder, lineWidth: 1)
        )
    }

    // MARK: - View mode

    private var viewMode: some View {
        HStack(alignment: .top, spacing: 9) {
            TypeTag(type: update.type)
                .padding(.top, 1)
            Text(update.text)
                .font(.system(size: 13))
                .foregroundStyle(palette.textNavy)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
            IconButton(systemName: "pencil", size: 24, iconSize: 12, action: startEdit)
                .help("Edit")
            IconButton(systemName: "trash", size: 24, iconSize: 12, hoverBackground: palette.redTint, action: onDelete)
                .help("Delete")
        }
    }

    // MARK: - Edit mode

    private var editView: some View {
        VStack(alignment: .leading, spacing: 7) {
            TextEditor(text: $editText)
                .font(.system(size: 13))
                .foregroundStyle(palette.textNavy)
                .scrollContentBackground(.hidden)
                .padding(4)
                .frame(height: 52)
                .background(palette.inputSoft)
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .strokeBorder(palette.grey6, lineWidth: 1)
                )

            HStack(spacing: 8) {
                Spacer(minLength: 0)
                cancelButton
                saveButton
            }
        }
    }

    private var cancelButton: some View {
        Button(action: cancelEdit) {
            Text("Cancel")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(palette.grey1)
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(palette.grey6, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }

    private var saveButton: some View {
        Button(action: saveEdit) {
            Text("Save")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.vertical, 5)
                .padding(.horizontal, 12)
                .background(palette.blue)
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func startEdit() {
        editText = update.text
        isEditing = true
    }

    private func cancelEdit() {
        isEditing = false
    }

    /// Saving an emptied draft deletes the update (matches the prototype's
    /// `onSaveEdit`, which filters the update out rather than persisting blank text).
    /// The update's type is left unchanged — it's not editable inline.
    private func saveEdit() {
        let trimmed = editText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            onDelete()
        } else {
            update.text = trimmed
        }
        isEditing = false
    }
}

#Preview {
    VStack(spacing: 6) {
        UpdateRow(update: DayUpdate(id: "1", type: .done, text: "Wired up the payment form", sortIndex: 0), onDelete: {})
        UpdateRow(update: DayUpdate(id: "2", type: .blocker, text: "Waiting on API keys from platform team", sortIndex: 1), onDelete: {})
    }
    .padding()
    .frame(width: 340)
    .environment(\.palette, SBPalette(.light))
}
