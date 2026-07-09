//
//  OffStateView.swift
//  SprintBuddy
//
//  The detail pane's centered "nothing to log here" state for leave/holiday/
//  weekend days: a tinted icon tile, a title, and a subtitle. Copy and colors
//  ported verbatim from the prototype's `offMap`
//  (design_handoff/project/ScrumBuddy.dc.html renderVals lines 1096-1100)
//  and markup lines 405-411.
//

import SwiftUI

struct OffStateView: View {
    let status: DayStatus

    @Environment(\.palette) private var palette

    private struct Copy {
        let title: String
        let subtitle: String
        let icon: String
        let color: Color
        let tint: Color
    }

    private var copy: Copy {
        switch status {
        case .leave:
            return Copy(
                title: "Marked as leave",
                subtitle: "This day is logged as leave and excluded from your working-day totals.",
                icon: "arrow.uturn.left",
                color: palette.error,
                tint: palette.redTint
            )
        case .holiday:
            return Copy(
                title: "Public holiday",
                subtitle: "No effort expected. Switch to Working if you did put in time.",
                icon: "calendar",
                color: palette.holidayText,
                tint: palette.amberTint
            )
        case .weekend, .working:
            // `.working` never reaches this view (DetailPane routes working days to the
            // composer), but the prototype's `offMap[day.status] || offMap.weekend`
            // fallback is mirrored here for safety.
            return Copy(
                title: "Weekend",
                subtitle: "Weekends are off by default. Switch to Working to log effort here.",
                icon: "clock",
                color: palette.grey2,
                tint: palette.muted
            )
        }
    }

    var body: some View {
        let c = copy
        VStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 19, style: .continuous)
                    .fill(c.tint)
                    .frame(width: 66, height: 66)
                Image(systemName: c.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(c.color)
            }

            Text(c.title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(palette.textNavy)

            Text(c.subtitle)
                .font(.system(size: 13))
                .lineSpacing(4)
                .multilineTextAlignment(.center)
                .foregroundStyle(palette.grey2)
                .frame(maxWidth: 250)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 36)
        .padding(.horizontal, 10)
    }
}

#Preview {
    VStack(spacing: 30) {
        OffStateView(status: .leave)
        OffStateView(status: .holiday)
        OffStateView(status: .weekend)
    }
    .frame(width: 340)
    .background(Color.white)
    .environment(\.palette, SBPalette(.light))
}
