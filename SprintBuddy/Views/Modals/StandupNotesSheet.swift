//
//  StandupNotesSheet.swift
//  SprintBuddy
//
//  The "Standup Notes" modal: a read-only monospaced dump of
//  `StandupFormatter.text(activeDTO)`, with Close + Copy-to-clipboard
//  actions. Transcribed from
//  design_handoff/project/ScrumBuddy.dc.html lines 448-456 (the modal
//  markup) and `copyToClipboard`/`exportText` around lines 778-812
//  (the 2s "Copied" flip after writing to the clipboard).
//
//  Presented by ContentView via `.sheet(isPresented: $appState.standupOpen)`.
//

import SwiftUI
import AppKit

struct StandupNotesSheet: View {
    let text: String
    let onClose: () -> Void

    @Environment(\.palette) private var palette
    @State private var copied = false
    @State private var copyResetTask: Task<Void, Never>?

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header
            body_
            footer
        }
        .padding(24)
        .frame(width: 560)
        .background(palette.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .onDisappear { copyResetTask?.cancel() }
    }

    // MARK: - Header

    private var header: some View {
        Text("Standup Notes")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(palette.textNavy)
    }

    // MARK: - Body (read-only monospaced text)

    private var body_: some View {
        ScrollView {
            Text(text)
                .font(.system(size: 12, design: .monospaced))
                .lineSpacing(4)
                .foregroundStyle(palette.textNavy)
                .frame(maxWidth: .infinity, alignment: .leading)
                .textSelection(.enabled)
                .padding(14)
        }
        .frame(height: 300)
        .background(palette.inputSoft)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(palette.grey6, lineWidth: 1)
        )
    }

    // MARK: - Footer

    private var footer: some View {
        HStack(spacing: 10) {
            Spacer()
            closeButton
            copyButton
        }
    }

    private var closeButton: some View {
        Button(action: onClose) {
            Text("Close")
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

    private var copyButton: some View {
        Button(action: copy) {
            HStack(spacing: 6) {
                Image(systemName: copied ? "checkmark" : "doc.on.doc")
                    .font(.system(size: 12, weight: .medium))
                Text(copied ? "Copied" : "Copy to Clipboard")
                    .font(.system(size: 13, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 10)
            .padding(.horizontal, 16)
            .background(palette.blue)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func copy() {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        copyResetTask?.cancel()
        copied = true
        copyResetTask = Task {
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled {
                copied = false
            }
        }
    }
}

#Preview {
    StandupNotesSheet(text: "Sprint 24 — Jul 6 – 19, 2026\nFocus: Ship the new checkout flow\nLogged 1 of 10 working days · 0 leave · 0 holiday\n\nMon, Jul 6\n  - [Done] Wired up the payment form", onClose: {})
        .environment(\.palette, SBPalette(.light))
}
