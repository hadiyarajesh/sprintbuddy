//
//  UpdateComposer.swift
//  SprintBuddy
//
//  The "Add update" composer at the top of the working-day detail pane:
//  a draft `TextEditor`, Done/Doing/Blocker type chips, and an Add button.
//  Transcribed from design_handoff/project/ScrumBuddy.dc.html lines 343-353
//  and the `⌘/Ctrl+Enter` shortcut wired via `onDraftKey`/`addUpdate`
//  (renderVals lines 1136-1143, addUpdate lines 1008-1017).
//

import SwiftUI
import SprintBuddyKit

struct UpdateComposer: View {
    @Binding var draftText: String
    @Binding var draftType: UpdateType
    let onAdd: () -> Void

    @Environment(\.palette) private var palette

    private var canAdd: Bool {
        !draftText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Add update")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(palette.textNavy)

            textEditor

            HStack(spacing: 6) {
                ForEach([UpdateType.done, .doing, .blocker], id: \.self) { t in
                    TypeChipButton(type: t, isSelected: draftType == t, action: { draftType = t })
                }
                Spacer(minLength: 0)
                addButton
            }
        }
    }

    // MARK: - Draft text editor

    private var textEditor: some View {
        ZStack(alignment: .topLeading) {
            TextEditor(text: $draftText)
                .font(.system(size: 13))
                .foregroundStyle(palette.textNavy)
                .scrollContentBackground(.hidden)
                .padding(6)
                // ⌘+Enter submits the draft.
                .onKeyPress(.return, phases: .down) { press in
                    guard press.modifiers.contains(.command) else { return .ignored }
                    if canAdd { onAdd() }
                    return .handled
                }

            if draftText.isEmpty {
                Text("What did you work on? (\u{2318} + Enter to add)")
                    .font(.system(size: 13))
                    .foregroundStyle(palette.grey4)
                    .padding(.horizontal, 11)
                    .padding(.top, 8)
                    .allowsHitTesting(false)
            }
        }
        .frame(height: 58)
        .background(palette.inputSoft)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(palette.grey6, lineWidth: 1)
        )
    }

    // MARK: - Add button

    private var addButton: some View {
        Button(action: onAdd) {
            HStack(spacing: 5) {
                Image(systemName: "plus")
                    .font(.system(size: 11, weight: .semibold))
                Text("Add")
                    .font(.system(size: 12.5, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 7)
            .padding(.horizontal, 14)
            .background(palette.blue)
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canAdd)
        .opacity(canAdd ? 1 : 0.55)
    }
}

#Preview {
    @Previewable @State var draftText = ""
    @Previewable @State var draftType: UpdateType = .done

    return UpdateComposer(draftText: $draftText, draftType: $draftType, onAdd: {})
        .padding()
        .frame(width: 340)
        .environment(\.palette, SBPalette(.light))
}
