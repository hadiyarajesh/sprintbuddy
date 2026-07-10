//
//  EmptyStateView.swift
//  SprintBuddy
//
//  Centered empty state shown in the board area when there are no sprints.
//  Transcribed from design_handoff/project/ScrumBuddy.dc.html lines 299-308
//  (`sc-if value="{{ noSprint }}"`).
//

import SwiftUI
import SprintBuddyKit

struct EmptyStateView: View {
    let onNew: () -> Void

    @Environment(\.palette) private var palette

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar")
                .font(.system(size: 46, weight: .regular))
                .foregroundStyle(palette.grey5)

            Text("No sprints yet")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(palette.textNavy)

            Text("Create a sprint to start logging your daily effort")
                .font(.system(size: 13))
                .foregroundStyle(palette.grey2)

            Button(action: onNew) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                    Text("New Sprint")
                        .font(.system(size: 13, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 16)
                .background(palette.blue)
                .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            }
            .buttonStyle(.plain)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    EmptyStateView(onNew: {})
        .frame(width: 600, height: 500)
        .environment(\.palette, SBPalette(.light))
}
