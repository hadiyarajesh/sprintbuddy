//
//  DeleteSprintSheet.swift
//  SprintBuddy
//
//  The "Delete Sprint" confirmation modal: names the sprint being removed
//  and warns the action is permanent. Transcribed from
//  design_handoff/project/ScrumBuddy.dc.html lines 458-467 (the modal
//  markup) and `confirmDelete` around lines 1287-1291.
//
//  Presented by ContentView via `.sheet(isPresented: $appState.deleteOpen)`.
//

import SwiftUI

struct DeleteSprintSheet: View {
    let sprintName: String
    let onCancel: () -> Void
    let onConfirm: () -> Void

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            header
            body_
            footer
        }
        .padding(24)
        .frame(width: 440)
        .background(palette.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
    }

    // MARK: - Header

    private var header: some View {
        Text("Delete Sprint")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(palette.textNavy)
    }

    // MARK: - Body

    private var body_: some View {
        (
            Text("This will permanently delete ")
            + Text(sprintName).fontWeight(.semibold)
            + Text(" and all of its logged effort. This action cannot be undone.")
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
            deleteButton
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

    private var deleteButton: some View {
        Button(action: onConfirm) {
            Text("Delete Sprint")
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
    DeleteSprintSheet(sprintName: "Sprint 24 — Checkout Revamp", onCancel: {}, onConfirm: {})
        .environment(\.palette, SBPalette(.light))
}
