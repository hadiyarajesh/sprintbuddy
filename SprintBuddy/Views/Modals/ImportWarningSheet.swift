//
//  ImportWarningSheet.swift
//  SprintBuddy
//
//  The "Replace all data?" confirmation modal shown before an import
//  overwrites existing sprints. Transcribed from
//  design_handoff/project/ScrumBuddy.dc.html lines 469-478 (the modal
//  markup) and `handleImportText`/`applyImport` around lines 859-878.
//
//  Presented by ContentView via `.sheet(isPresented: $appState.importWarnOpen)`.
//

import SwiftUI

struct ImportWarningSheet: View {
    let currentCount: Int
    let pendingCount: Int
    let onCancel: () -> Void
    let onConfirm: () -> Void

    @Environment(\.palette) private var palette

    private var currentLabel: String { currentCount == 1 ? "sprint" : "sprints" }
    private var pendingLabel: String { pendingCount == 1 ? "sprint" : "sprints" }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            body_
            footer
        }
        .padding(24)
        .frame(width: 460)
        .background(palette.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    // MARK: - Header

    private var header: some View {
        Text("Replace all data?")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(palette.textNavy)
    }

    // MARK: - Body

    private var body_: some View {
        (
            Text("Importing will ")
            + Text("replace all current data").fontWeight(.semibold)
            + Text(". Your \(currentCount) existing \(currentLabel) will be overwritten with \(pendingCount) imported \(pendingLabel). This cannot be undone \u{2014} export first if you want a backup.")
        )
        .font(.system(size: 13))
        .lineSpacing(6)
        .foregroundStyle(palette.textNavy)
        .fixedSize(horizontal: false, vertical: true)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 10) {
            Spacer()
            cancelButton
            confirmButton
        }
    }

    private var cancelButton: some View {
        Button(action: onCancel) {
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

    private var confirmButton: some View {
        Button(action: onConfirm) {
            Text("Replace & Import")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(palette.error)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ImportWarningSheet(currentCount: 3, pendingCount: 5, onCancel: {}, onConfirm: {})
        .environment(\.palette, SBPalette(.light))
}
