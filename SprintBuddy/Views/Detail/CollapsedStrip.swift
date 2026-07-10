//
//  CollapsedStrip.swift
//  SprintBuddy
//
//  The 54pt collapsed replacement for the detail pane: an expand button and
//  the selected day's long date rendered vertically. The whole strip is
//  tappable to re-expand. Transcribed from
//  design_handoff/project/ScrumBuddy.dc.html lines 416-421.
//

import SwiftUI
import SprintBuddyKit

struct CollapsedStrip: View {
    let dateLong: String
    let onExpand: () -> Void

    @Environment(\.palette) private var palette
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 16) {
            IconButton(systemName: "chevron.left", size: 32, iconSize: 13, action: onExpand)

            Text(dateLong.uppercased())
                .font(.system(size: 11, weight: .bold))
                .tracking(1)
                .foregroundStyle(palette.grey2)
                .fixedSize()
                .rotationEffect(.degrees(-90))
                .frame(width: 20)

            Spacer(minLength: 0)
        }
        .padding(.top, 18)
        .frame(width: 54)
        .frame(maxHeight: .infinity)
        .background(isHovering ? Color(hex: "eef3fb") : palette.sidebar)
        .overlay(alignment: .leading) {
            Rectangle().fill(palette.border).frame(width: 1)
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onExpand)
        .onHover { isHovering = $0 }
    }
}

#Preview {
    CollapsedStrip(dateLong: "July 9, 2026", onExpand: {})
        .frame(height: 600)
        .environment(\.palette, SBPalette(.light))
}
