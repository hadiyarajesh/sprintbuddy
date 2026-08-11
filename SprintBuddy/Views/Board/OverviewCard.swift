//
//  OverviewCard.swift
//  SprintBuddy
//
//  The board's top summary card: sprint name, status pill, range, an
//  editable focus line, a progress bar, and stat pills. Transcribed from
//  design_handoff/project/ScrumBuddy.dc.html lines 209-248, with the
//  status-pill color map from `renderVals` lines 1026-1029 and the
//  progress/stat-pill values from lines 1055-1078.
//

import SwiftUI
import SprintBuddyKit
import SwiftData

struct OverviewCard: View {
    @Bindable var sprint: Sprint
    let dto: SprintDTO
    let today: String
    let onDelete: () -> Void
    let onStandup: () -> Void
    let onSummary: () -> Void
    let isReadOnly: Bool

    @Environment(\.palette) private var palette
    @State private var isHoveringDelete = false
    @State private var isHoveringSummary = false

    private var status: SprintMath.SprintStatus { SprintMath.status(dto, today: today) }
    private var stats: SprintMath.Stats { SprintMath.stats(dto) }
    private var progressPct: Int { SprintMath.progressPct(dto) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            headerRow
            progressRow
                .padding(.top, 16)
        }
        .padding(.vertical, 22)
        .padding(.horizontal, 24)
        .background(palette.white)
        .clipShape(RoundedRectangle(cornerRadius: Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                .strokeBorder(palette.cardBorder, lineWidth: 1)
        )
        .shadow(color: Color.rgba(19, 19, 76, 0.04), radius: 1, x: 0, y: 1)
        .shadow(color: Color.rgba(19, 19, 76, 0.2), radius: 14, x: 0, y: 8)
    }

    // MARK: - Header row (name, status/range/day-chip, focus, actions)

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                TextField("Sprint name", text: $sprint.name)
        .textFieldStyle(.plain)
                    .font(.system(size: 25, weight: .bold))
                    .tracking(-0.3)
                    .foregroundStyle(palette.blue)
            .lineLimit(1)
            .disabled(isReadOnly)

                metaRow
                    .padding(.top, 8)

                focusField
                    .padding(.top, 12)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            actionButtons
        }
    }

    private var metaRow: some View {
        let style = OverviewCard.statusStyle(status, palette)

        return HStack(spacing: 10) {
            StatusPill(label: style.label, dotColor: style.dot, textColor: style.text, background: style.bg)

            Text(SprintMath.rangeLabel(dto) + " \u{00b7} \(dto.weeks)-week sprint")
                .font(.system(size: 13))
                .foregroundStyle(palette.grey1)

            if let idx = SprintMath.dayIndex(dto, today: today) {
                Text("Day \(idx) of \(dto.weeks * 7)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(palette.grey1)
                    .padding(.vertical, 2)
                    .padding(.horizontal, 10)
                    .background(palette.hover)
                    .clipShape(Capsule())
            }
        }
    }

    private var focusField: some View {
        TextField("Add a focus for this sprint\u{2026}", text: $sprint.focus)
            .textFieldStyle(.plain)
            .font(.system(size: 14))
            .foregroundStyle(palette.grey1)
        .frame(maxWidth: 560, alignment: .leading)
        .disabled(isReadOnly)
    }

    private var actionButtons: some View {
        HStack(spacing: 8) {
            IconButton(systemName: "square.and.arrow.up", size: 32, iconSize: 14, action: onStandup)
                .help("Standup Notes")
            Button(action: onSummary) {
                Image(systemName: "sparkles")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [palette.blue, palette.success],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .background(isHoveringSummary ? palette.blueTint : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .strokeBorder(palette.blueTintBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .onHover { isHoveringSummary = $0 }
            .help("Generate sprint summary")

            Button(action: onDelete) {
                Image(systemName: "trash")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(palette.error)
                    .frame(width: 32, height: 32)
                    .background(isHoveringDelete ? palette.redTint : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                            .strokeBorder(palette.redTintBorder, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .onHover { isHoveringDelete = $0 }
            .help("Delete Sprint")
        }
        .frame(width: 32 * 3 + 16, alignment: .trailing)
    }

    // MARK: - Progress row (bar + stat pills)

    private var progressRow: some View {
        HStack(alignment: .bottom, spacing: 18) {
            VStack(alignment: .leading, spacing: 7) {
                HStack(alignment: .firstTextBaseline) {
                    Text("Progress")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(palette.textNavy)
                    Spacer()
                    Text("\(stats.logged) of \(stats.working) working days \u{00b7} \(progressPct)%")
                        .font(.system(size: 12))
                        .foregroundStyle(palette.grey2)
                }
                progressTrack
            }
            .frame(minWidth: 0, maxWidth: .infinity)

            statPills
        }
    }

    private var progressTrack: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(palette.chip)
                Capsule()
                    .fill(LinearGradient(colors: [palette.blue, Color(hex: "4eb55c")], startPoint: .leading, endPoint: .trailing))
                    .frame(width: geo.size.width * CGFloat(progressPct) / 100)
            }
        }
        .frame(height: 8)
    }

    private var statPills: some View {
        HStack(spacing: 8) {
            StatPill(
                value: "\(stats.logged)/\(stats.working)",
                label: "logged",
                color: palette.blue,
                tint: palette.blueTint,
                border: palette.blueTintBorder
            )
            if stats.leave > 0 {
                StatPill(
                    value: "\(stats.leave)",
                    label: stats.leave == 1 ? "leave" : "leaves",
                    color: palette.error,
                    tint: palette.redTint,
                    border: palette.redTintBorder
                )
            }
            if stats.holiday > 0 {
                StatPill(
                    value: "\(stats.holiday)",
                    label: stats.holiday == 1 ? "holiday" : "holidays",
                    color: palette.holidayText,
                    tint: palette.amberTint,
                    border: palette.amberTintBorder
                )
            }
        }
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Status pill color map (`renderVals` lines 1026-1029)

    private static func statusStyle(_ status: SprintMath.SprintStatus, _ p: SBPalette) -> (dot: Color, bg: Color, text: Color, label: String) {
        switch status {
        case .active: return (p.success, p.greenTint, p.successDark, "Active")
        case .completed: return (p.grey4, p.muted, p.grey1, "Completed")
        case .upcoming: return (p.warning, p.amberTint, p.holidayText, "Upcoming")
        }
    }
}

#Preview {
    let sprint = Sprint(id: "1", name: "Sprint 24 \u{2014} Checkout Revamp", focus: "Ship the new checkout flow", startISO: "2026-07-06", weeks: 2)
    return OverviewCard(sprint: sprint, dto: sprint.toDTO(), today: "2026-07-09", onDelete: {}, onStandup: {}, onSummary: {}, isReadOnly: false)
        .padding()
        .frame(width: 900)
        .environment(\.palette, SBPalette(.light))
}
