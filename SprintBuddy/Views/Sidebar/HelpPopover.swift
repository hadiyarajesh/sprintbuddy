//
//  HelpPopover.swift
//  SprintBuddy
//
//  The Help popover attached to the sidebar footer's "Help" button: a
//  "Quick tips" label followed by three numbered tips.
//
//  Copy is verbatim from design_handoff/project/ScrumBuddy.dc.html lines
//  194-196.
//

import SwiftUI
import SprintBuddyKit

struct HelpPopover: View {
    @Environment(\.palette) private var palette

    private static let tips: [String] = [
        "Create a sprint and SprintBuddy generates a card for every day.",
        "Click any day to log effort or mark it as leave or holiday.",
        "Tag each update Done, Doing, or Blocker; back up or move data with JSON export/import.",
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("QUICK TIPS")
                .font(.system(size: 12, weight: .bold))
                .tracking(0.6)
                .foregroundStyle(palette.grey2)

            VStack(alignment: .leading, spacing: 9) {
                ForEach(Array(Self.tips.enumerated()), id: \.offset) { index, tip in
                    tipRow(number: index + 1, text: tip)
                }
            }
        }
        .padding(14)
        .frame(width: 258)
        .background(palette.white)
    }

    private func tipRow(number: Int, text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("\(number)")
                .font(.system(size: 12.5, weight: .bold))
                .foregroundStyle(palette.blue)
            Text(text)
                .font(.system(size: 12.5))
                .foregroundStyle(palette.grey1)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

#Preview {
    HelpPopover()
        .environment(\.palette, SBPalette(.light))
}
