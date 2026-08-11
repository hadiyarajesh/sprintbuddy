//
//  SprintSummarySheet.swift
//  SprintBuddy
//
//  A local-only sprint recap sheet. The system model receives sprint activity
//  and metadata, never private notes.
//

import SwiftUI
import SprintBuddyKit
import AppKit

struct SprintSummarySheet: View {
    let sprint: SprintDTO
    let onClose: () -> Void

    @Environment(\.palette) private var palette
    @State private var state: SummaryState = .loading
    @State private var copied = false
    @State private var copyResetTask: Task<Void, Never>?

    private enum SummaryState {
        case loading
        case summary(String)
        case unavailable(String)
        case failure(String)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            header
            bodyContent
            footer
        }
        .padding(24)
        .frame(width: 580)
        .background(palette.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .task { await loadSummary() }
        .onDisappear { copyResetTask?.cancel() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .foregroundStyle(palette.blue)
                Text("Sprint Summary")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(palette.textNavy)
            }
            Text("Generated on this Mac from sprint activity. Private notes are excluded.")
                .font(.system(size: 12))
                .foregroundStyle(palette.grey2)
        }
    }

    @ViewBuilder
    private var bodyContent: some View {
        switch state {
        case .loading:
            HStack(spacing: 10) {
                ProgressView().controlSize(.small)
                Text("Creating your summary…")
                    .font(.system(size: 13))
                    .foregroundStyle(palette.grey1)
            }
            .frame(maxWidth: .infinity, minHeight: 210, alignment: .center)
            .background(palette.inputSoft)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        case .summary(let text):
            ScrollView {
                summaryBody(text)
                    .padding(14)
            }
            .frame(height: 260)
            .background(palette.inputSoft)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(palette.grey6, lineWidth: 1))
        case .unavailable(let message), .failure(let message):
            VStack(spacing: 10) {
                Image(systemName: "apple.intelligence")
                    .font(.system(size: 28))
                    .foregroundStyle(palette.grey3)
                Text(message)
                    .font(.system(size: 13))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(palette.grey1)
                    .frame(maxWidth: 390)
            }
            .frame(maxWidth: .infinity, minHeight: 210)
            .background(palette.inputSoft)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }

    private var footer: some View {
        HStack(spacing: 10) {
            if case .summary(let text) = state {
                Button(action: { copy(text) }) {
                    Label(copied ? "Copied" : "Copy", systemImage: copied ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(palette.blue)
                }
                .buttonStyle(.plain)
                Button(action: { Task { await generate() } }) {
                    Label("Generate again", systemImage: "arrow.clockwise")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(palette.blue)
                }
                .buttonStyle(.plain)
            }
            Spacer()
            Button(action: onClose) {
                Text("Close")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(palette.ink)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 16)
                    .overlay(RoundedRectangle(cornerRadius: Radius.md, style: .continuous).strokeBorder(palette.border2, lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    @MainActor
    private func generate() async {
        state = .loading
        copied = false
        switch await SprintSummaryGenerator.generate(for: sprint) {
        case .success(let text):
            SprintSummaryCache.store(text, for: sprint)
            state = .summary(text)
        case .unavailable(let message): state = .unavailable(message)
        case .failure(let message): state = .failure(message)
        }
    }

    @MainActor
    private func loadSummary() async {
        if let cached = SprintSummaryCache.summary(for: sprint) {
            state = .summary(cached)
        } else {
            await generate()
        }
    }

    private func copy(_ text: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        copyResetTask?.cancel()
        copied = true
        copyResetTask = Task {
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled { copied = false }
        }
    }

    private func summaryBody(_ text: String) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(text.components(separatedBy: .newlines).enumerated()), id: \.offset) { index, line in
                summaryLine(line, isFirst: index == 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .textSelection(.enabled)
    }

    @ViewBuilder
    private func summaryLine(_ line: String, isFirst: Bool) -> some View {
        let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
        if let title = sectionTitle(in: trimmed) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(palette.textNavy)
                .padding(.top, isFirst ? 0 : 15)
                .padding(.bottom, 6)
        } else if let item = bulletText(in: trimmed) {
            HStack(alignment: .top, spacing: 8) {
                Circle()
                    .fill(palette.blue)
                    .frame(width: 5, height: 5)
                    .padding(.top, 6)
                Text(inlineMarkdown(item))
                    .font(.system(size: 13))
                    .lineSpacing(3)
                    .foregroundStyle(palette.textNavy)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.bottom, 6)
        } else if !trimmed.isEmpty {
            Text(inlineMarkdown(trimmed))
                .font(.system(size: 13))
                .lineSpacing(3)
                .foregroundStyle(palette.textNavy)
                .padding(.bottom, 6)
        }
    }

    private func sectionTitle(in line: String) -> String? {
        let normalized = line.trimmingCharacters(in: CharacterSet(charactersIn: "#* _")).lowercased()
        switch normalized {
        case "delivered": return "Delivered"
        case "in progress": return "In progress"
        case "blocked": return "Blocked"
        default: return nil
        }
    }

    private func bulletText(in line: String) -> String? {
        guard line.hasPrefix("-") || line.hasPrefix("•") else { return nil }
        return String(line.dropFirst()).trimmingCharacters(in: .whitespaces)
    }

    private func inlineMarkdown(_ text: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        return (try? AttributedString(markdown: text, options: options)) ?? AttributedString(text)
    }
}

#Preview {
    SprintSummarySheet(
        sprint: SprintDTO(id: "1", name: "Checkout", description: "Ship the checkout flow", start: "2026-08-03", weeks: 1, days: [:]),
        onClose: {}
    )
    .environment(\.palette, SBPalette(.light))
}
