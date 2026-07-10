//
//  DayCell.swift
//  SprintBuddy
//
//  A single day card in the board's 5-column grid. Ports the `buildCells`
//  per-cell state machine from
//  design_handoff/project/ScrumBuddy.dc.html lines 902-978 (bg/border/shadow/
//  labelColor selection, update previews, "Not logged" warning, empty-day
//  affordance, today/selected emphasis) and its markup at lines 251-295.
//

import SwiftUI
import SprintBuddyKit

struct DayCell: View {
    let day: DayDTO
    let isoDate: String
    let isToday: Bool
    let isSelected: Bool
    /// Precomputed by the caller: `highlightUnlogged && working && isPast && !logged && !isToday`.
    let notLogged: Bool
    let onSelect: () -> Void

    @Environment(\.palette) private var palette
    @State private var isHovering = false

    // MARK: - Derived state

    private var working: Bool { day.status == .working }
    private var logged: Bool { working && !day.updates.isEmpty }
    private var emptyHint: Bool { working && !logged && !notLogged }

    /// Resolved bg/border/shadow/label for the current status + today/selected emphasis,
    /// mirroring `buildCells` line-by-line.
    private struct Style {
        var bg: Color
        var borderColor: Color
        var borderWidth: CGFloat
        var dashed: Bool
        var showShadow: Bool
        var labelColor: Color
    }

    private var style: Style {
        let p = palette
        var bg = p.white
        var borderColor = p.cardBorder2
        var borderWidth: CGFloat = 1
        var dashed = false
        var showShadow = true
        var labelColor = p.textNavy

        switch day.status {
        case .weekend:
            bg = p.muted
            borderColor = p.weekendBorder
            showShadow = false
            labelColor = p.grey4
        case .leave:
            borderColor = p.leaveBorder
        case .holiday:
            borderColor = p.holidayBorder
        case .working:
            if !logged {
                borderColor = p.dashed
                borderWidth = 1.5
                dashed = true
                showShadow = false
            }
            if notLogged {
                borderColor = p.dashedWarn
                borderWidth = 1.5
                dashed = true
                showShadow = false
            }
        }

        // Today / selected emphasis — selected takes precedence over today.
        if isToday && !isSelected {
            borderColor = p.blue
            borderWidth = 1.5
            dashed = false
            bg = p.todayBg
            showShadow = false
            labelColor = p.blue
        }
        if isSelected {
            borderColor = p.blue
            borderWidth = 2
            dashed = false
            // Prototype (buildCells:942-943) REPLACES the ambient shadow with the
            // focus ring on selection — a selected cell shows only the ring.
            showShadow = false
            if working {
                bg = p.todayBg
                labelColor = p.blue
            }
        }

        return Style(bg: bg, borderColor: borderColor, borderWidth: borderWidth, dashed: dashed, showShadow: showShadow, labelColor: labelColor)
    }

    private var showDot: Bool { day.status == .leave || day.status == .holiday }
    private var dotColor: Color { day.status == .leave ? palette.error : palette.warning }

    private var dateStr: String {
        let d = DateKey.parse(isoDate)
        let dd = Calendar.current.component(.day, from: d)
        let mm = Calendar.current.component(.month, from: d)
        return String(format: "%02d/%02d", dd, mm)
    }

    private var weekdayStr: String { SprintMath.weekdayShort(DateKey.parse(isoDate)) }

    // MARK: - Body

    var body: some View {
        let s = style

        VStack(alignment: .leading, spacing: 8) {
            header(s)
            content
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 13)
        .frame(maxWidth: .infinity, minHeight: 148, alignment: .topLeading)
        .background(s.bg)
        .clipShape(RoundedRectangle(cornerRadius: Radius.cell, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.cell, style: .continuous)
                .strokeBorder(s.borderColor, style: StrokeStyle(lineWidth: s.borderWidth, dash: s.dashed ? [5, 4] : []))
        )
        // Approximates the prototype's `box-shadow: 0 0 0 3px rgba(42,118,225,0.14)`
        // focus ring on selected cells — SwiftUI has no spread-shadow primitive, so an
        // outset stroked rounded-rect stands in for it.
        .overlay {
            if isSelected {
                RoundedRectangle(cornerRadius: Radius.cell + 2, style: .continuous)
                    .strokeBorder(Color.rgba(42, 118, 225, 0.14), lineWidth: 3)
                    .padding(-3)
            }
        }
        .shadow(color: s.showShadow ? Color.rgba(19, 19, 76, 0.05) : .clear, radius: 2, x: 0, y: 1)
        .shadow(color: s.showShadow ? Color.rgba(19, 19, 76, 0.16) : .clear, radius: 6, x: 0, y: 4)
        .offset(y: isHovering ? -3 : 0)
        .animation(.easeOut(duration: 0.15), value: isHovering)
        .onHover { isHovering = $0 }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSelect)
    }

    // MARK: - Header

    private func header(_ s: Style) -> some View {
        HStack(alignment: .top, spacing: 6) {
            // When the pane is open the cells get narrow; keep the date/weekday/TODAY
            // pill from breaking mid-word by picking a one-line layout when it fits and
            // dropping the TODAY pill to a second line (as a whole) when it doesn't.
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    dateText(s)
                    weekdayText
                    todayPill
                }
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 6) {
                        dateText(s)
                        weekdayText
                    }
                    todayPill
                }
            }
            Spacer(minLength: 0)
            if showDot {
                Circle()
                    .fill(dotColor)
                    .frame(width: 9, height: 9)
                    .padding(.top, 3)
            }
        }
    }

    private func dateText(_ s: Style) -> some View {
        Text(dateStr)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(s.labelColor)
            .lineLimit(1)
            .fixedSize()
    }

    private var weekdayText: some View {
        Text(weekdayStr)
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(palette.grey3)
            .lineLimit(1)
            .fixedSize()
    }

    @ViewBuilder
    private var todayPill: some View {
        if isToday {
            Text("TODAY")
                .font(.system(size: 9, weight: .bold))
                .tracking(0.4)
                .foregroundStyle(.white)
                .lineLimit(1)
                .fixedSize()
                .padding(.vertical, 1)
                .padding(.horizontal, 6)
                .background(palette.blue)
                .clipShape(Capsule())
        }
    }

    // MARK: - Body content (mutually exclusive per `buildCells`)

    @ViewBuilder
    private var content: some View {
        if logged {
            previewSection
        } else if day.status == .leave || day.status == .holiday {
            statusSection
        } else if notLogged {
            notLoggedRow
        } else if emptyHint {
            emptyHintSection
        } else {
            EmptyView()
        }
    }

    private var previewSection: some View {
        VStack(alignment: .leading, spacing: 3) {
            ForEach(Array(day.updates.prefix(3).enumerated()), id: \.offset) { _, update in
                HStack(alignment: .top, spacing: 6) {
                    Circle()
                        .fill(UpdateMeta.color(update.type, palette))
                        .frame(width: 6, height: 6)
                        .padding(.top, 5)
                    Text(update.text)
                        .font(.system(size: 12))
                        .foregroundStyle(palette.textNavy)
                        .lineLimit(2)
                        .truncationMode(.tail)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if day.updates.count > 3 {
                Text("+\(day.updates.count - 3) more")
                    .font(.system(size: 11))
                    .foregroundStyle(palette.grey3)
                    .padding(.leading, 10)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    private var statusSection: some View {
        let isLeave = day.status == .leave
        let color = isLeave ? palette.error : palette.holidayText
        let label = isLeave ? "On leave" : "Holiday"
        return VStack {
            Spacer(minLength: 0)
            HStack(spacing: 5) {
                Circle().fill(color).frame(width: 6, height: 6)
                Text(label)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(color)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
    }

    private var notLoggedRow: some View {
        HStack(spacing: 5) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 10, weight: .semibold))
            Text("Not logged")
                .font(.system(size: 10.5, weight: .semibold))
        }
        .foregroundStyle(palette.warning)
    }

    private var emptyHintSection: some View {
        ZStack {
            Circle()
                .fill(palette.hover)
                .frame(width: 30, height: 30)
            Image(systemName: "plus")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(palette.grey4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Cell states") {
    let p = SBPalette(.light)
    return LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4), spacing: 12) {
        DayCell(day: DayDTO(status: .working, updates: [UpdateDTO(id: "1", type: .done, text: "Shipped the login flow")]), isoDate: "2026-07-06", isToday: false, isSelected: false, notLogged: false, onSelect: {})
        DayCell(day: DayDTO(status: .working), isoDate: "2026-07-13", isToday: false, isSelected: false, notLogged: false, onSelect: {})
        DayCell(day: DayDTO(status: .working), isoDate: "2026-07-01", isToday: false, isSelected: false, notLogged: true, onSelect: {})
        DayCell(day: DayDTO(status: .leave), isoDate: "2026-07-08", isToday: false, isSelected: false, notLogged: false, onSelect: {})
        DayCell(day: DayDTO(status: .holiday), isoDate: "2026-07-09", isToday: true, isSelected: false, notLogged: false, onSelect: {})
        DayCell(day: DayDTO(status: .weekend), isoDate: "2026-07-11", isToday: false, isSelected: false, notLogged: false, onSelect: {})
        DayCell(day: DayDTO(status: .working), isoDate: "2026-07-14", isToday: false, isSelected: true, notLogged: false, onSelect: {})
    }
    .padding()
    .background(p.boardGradient)
    .environment(\.palette, p)
}
