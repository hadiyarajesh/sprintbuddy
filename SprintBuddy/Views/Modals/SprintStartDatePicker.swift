//
//  SprintStartDatePicker.swift
//  SprintBuddy
//
//  App-styled calendar control for choosing a new sprint's first day. It
//  replaces macOS's compact native date picker with a legible month grid.
//

import SwiftUI
import SprintBuddyKit

struct SprintStartDatePicker: View {
    @Binding var selection: Date

    @Environment(\.palette) private var palette
    @State private var isOpen = false

    private var label: String {
        selection.formatted(.dateTime.month(.abbreviated).day().year())
    }

    var body: some View {
        Button { isOpen.toggle() } label: {
            HStack(spacing: 9) {
                Image(systemName: "calendar")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(palette.blue)
                    .frame(width: 16)
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(palette.textNavy)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundStyle(palette.grey3)
            }
            .padding(.vertical, 10)
            .padding(.horizontal, 11)
            .background(palette.inputSoft)
            .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                    .strokeBorder(isOpen ? palette.blue : palette.border2, lineWidth: isOpen ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .popover(isPresented: $isOpen, arrowEdge: .bottom) {
            SprintCalendar(selection: $selection, isPresented: $isOpen)
                .environment(\.palette, palette)
        }
        .help("Choose sprint start date")
    }
}

private struct SprintCalendar: View {
    @Binding var selection: Date
    @Binding var isPresented: Bool

    @Environment(\.palette) private var palette
    @State private var displayedMonth: Date

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 3), count: 7)

    init(selection: Binding<Date>, isPresented: Binding<Bool>) {
        self._selection = selection
        self._isPresented = isPresented
        self._displayedMonth = State(initialValue: Self.monthStart(selection.wrappedValue))
    }

    private var monthTitle: String {
        displayedMonth.formatted(.dateTime.month(.wide).year())
    }

    private var weekdayNames: [String] {
        let symbols = calendar.veryShortWeekdaySymbols
        return (0..<7).map { symbols[(calendar.firstWeekday - 1 + $0) % 7] }
    }

    private var days: [Date?] {
        guard let range = calendar.range(of: .day, in: .month, for: displayedMonth),
              let first = calendar.date(from: calendar.dateComponents([.year, .month], from: displayedMonth)) else {
            return []
        }
        let weekday = calendar.component(.weekday, from: first)
        let leading = (weekday - calendar.firstWeekday + 7) % 7
        var result = Array<Date?>(repeating: nil, count: leading)
        result += range.compactMap { calendar.date(byAdding: .day, value: $0 - 1, to: first).map(DateKey.noon) }
        result += Array(repeating: nil, count: max(0, 42 - result.count))
        return result
    }

    var body: some View {
        VStack(spacing: 14) {
            monthNavigation
            weekdayHeader
            LazyVGrid(columns: columns, spacing: 4) {
                ForEach(Array(days.enumerated()), id: \.offset) { _, date in
                    if let date {
                        dayButton(date)
                    } else {
                        Color.clear.frame(width: 34, height: 34)
                    }
                }
            }
            footer
        }
        .padding(16)
        .frame(width: 312)
        .background(palette.white)
    }

    private var monthNavigation: some View {
        HStack(spacing: 8) {
            calendarButton("chevron.left", help: "Previous month") { moveMonth(by: -1) }
            Spacer()
            Text(monthTitle)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(palette.textNavy)
            Spacer()
            calendarButton("chevron.right", help: "Next month") { moveMonth(by: 1) }
        }
    }

    private var weekdayHeader: some View {
        LazyVGrid(columns: columns, spacing: 3) {
            ForEach(weekdayNames, id: \.self) { name in
                Text(name.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(palette.grey3)
                    .frame(height: 18)
            }
        }
    }

    private var footer: some View {
        HStack {
            Button("Today") {
                selection = DateKey.today()
                displayedMonth = Self.monthStart(selection)
                isPresented = false
            }
            .font(.system(size: 12, weight: .semibold))
            .foregroundStyle(palette.blue)
            .buttonStyle(.plain)

            Spacer()

            Text(selection.formatted(.dateTime.month(.abbreviated).day().year()))
                .font(.system(size: 11.5, weight: .medium))
                .foregroundStyle(palette.grey2)
        }
        .padding(.top, 2)
    }

    private func dayButton(_ date: Date) -> some View {
        let isSelected = calendar.isDate(date, inSameDayAs: selection)
        let isToday = calendar.isDateInToday(date)
        let weekday = calendar.component(.weekday, from: date)
        let isWeekend = weekday == 1 || weekday == 7

        return Button {
            selection = DateKey.noon(date)
            isPresented = false
        } label: {
            Text("\(calendar.component(.day, from: date))")
                .font(.system(size: 12, weight: isSelected || isToday ? .bold : .medium))
                .foregroundStyle(isSelected ? Color.white : (isWeekend ? palette.grey3 : palette.textNavy))
                .frame(width: 34, height: 34)
                .background(isSelected ? palette.blue : (isToday ? palette.blueTint : Color.clear))
                .clipShape(Circle())
                .overlay {
                    if isToday && !isSelected {
                        Circle().strokeBorder(palette.blueTintBorder, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .help(date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
    }

    private func calendarButton(_ icon: String, help: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(palette.grey1)
                .frame(width: 28, height: 28)
                .background(palette.inputSoft)
                .clipShape(Circle())
                .overlay(Circle().strokeBorder(palette.border2, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .help(help)
    }

    private func moveMonth(by offset: Int) {
        displayedMonth = calendar.date(byAdding: .month, value: offset, to: displayedMonth).map(Self.monthStart) ?? displayedMonth
    }

    private static func monthStart(_ date: Date) -> Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: date)) ?? date
    }
}
