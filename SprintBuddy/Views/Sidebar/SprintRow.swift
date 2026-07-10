//
//  SprintRow.swift
//  SprintBuddy
//
//  A single sprint entry in the sidebar's Active/Archive lists: a calendar
//  glyph, the sprint name, and its date range. Selected rows get a tinted
//  background; unselected rows get a lighter hover background.
//
//  Transcribed from design_handoff/project/ScrumBuddy.dc.html lines ~101-108
//  (the `sc-for` row inside the Active/Archive sections).
//

import SwiftUI
import SprintBuddyKit

struct SprintRow: View {
    let sprint: Sprint
    let isSelected: Bool
    let onSelect: () -> Void

    @Environment(\.palette) private var palette
    @State private var isHovering = false

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "calendar")
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(isSelected ? palette.blue : palette.grey3)
                    .padding(.top, 1)

                VStack(alignment: .leading, spacing: 2) {
                    Text(sprint.name)
                        .font(.system(size: 13.5, weight: isSelected ? .bold : .medium))
                        .foregroundStyle(isSelected ? palette.blue : palette.textNavy)
                        .lineLimit(1)
                        .truncationMode(.tail)

                    Text(SprintMath.rangeShort(sprint.toDTO()))
                        .font(.system(size: 11.5))
                        .foregroundStyle(palette.grey2)
                }
            }
            .padding(.vertical, 9)
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(isSelected ? palette.navActive : (isHovering ? palette.hover2 : Color.clear))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovering = $0 }
    }
}

#Preview {
    VStack(spacing: 4) {
        SprintRow(sprint: Sprint(id: "1", name: "Sprint 24 — Checkout Revamp", focus: "", startISO: "2026-07-01", weeks: 2), isSelected: true, onSelect: {})
        SprintRow(sprint: Sprint(id: "2", name: "Sprint 23", focus: "", startISO: "2026-06-15", weeks: 2), isSelected: false, onSelect: {})
    }
    .padding()
    .frame(width: 274)
    .environment(\.palette, SBPalette(.light))
}
