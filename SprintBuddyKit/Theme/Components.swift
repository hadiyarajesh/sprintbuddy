//
//  Components.swift
//  SprintBuddyKit
//
//  Shared, reusable SwiftUI views. All components read the current `SBPalette`
//  via `@Environment(\.palette)` so callers never thread colors through
//  explicitly (see Theme.swift for the environment key).
//

import SwiftUI

// MARK: - StatusPill

/// Dot + label pill on a tinted background, used for sprint status (Active / Completed / Upcoming).
public struct StatusPill: View {
    let label: String
    let dotColor: Color
    let textColor: Color
    let background: Color

    public init(label: String, dotColor: Color, textColor: Color, background: Color) {
        self.label = label; self.dotColor = dotColor; self.textColor = textColor; self.background = background
    }

    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(dotColor)
                .frame(width: 7, height: 7)
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(textColor)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 11)
        .background(background)
        .clipShape(Capsule())
    }
}

// MARK: - StatPill

/// Value + label pill for overview stats (e.g. "4/5 logged"), tinted with a matching border.
public struct StatPill: View {
    let value: String
    let label: String
    let color: Color
    let tint: Color
    let border: Color

    @Environment(\.palette) private var palette

    public init(value: String, label: String, color: Color, tint: Color, border: Color) {
        self.value = value; self.label = label; self.color = color; self.tint = tint; self.border = border
    }

    public var body: some View {
        HStack(spacing: 7) {
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(color)
                .lineSpacing(0)
            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundStyle(palette.grey1)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 11)
        .background(tint)
        .clipShape(RoundedRectangle(cornerRadius: Radius.md, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Radius.md, style: .continuous)
                .strokeBorder(border, lineWidth: 1)
        )
    }
}

// MARK: - TypeTag

/// Small rounded tag showing an update's type (Done / Doing / Blocker), colored via `UpdateMeta`.
public struct TypeTag: View {
    let type: UpdateType

    @Environment(\.palette) private var palette

    public init(type: UpdateType) { self.type = type }

    public var body: some View {
        Text(UpdateMeta.label(type).uppercased())
            .font(.system(size: 10, weight: .bold))
            .tracking(0.3)
            .foregroundStyle(UpdateMeta.color(type, palette))
            .padding(.vertical, 3)
            .padding(.horizontal, 8)
            .background(UpdateMeta.tint(type, palette))
            .clipShape(Capsule())
    }
}

// MARK: - TypeChipButton

/// Selectable pill used in the update composer to pick Done / Doing / Blocker.
public struct TypeChipButton: View {
    let type: UpdateType
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.palette) private var palette

    public init(type: UpdateType, isSelected: Bool, action: @escaping () -> Void) {
        self.type = type; self.isSelected = isSelected; self.action = action
    }

    public var body: some View {
        let color = UpdateMeta.color(type, palette)

        Button(action: action) {
            HStack(spacing: 5) {
                Circle()
                    .fill(color)
                    .frame(width: 7, height: 7)
                Text(UpdateMeta.label(type))
                    .font(.system(size: 11.5, weight: .semibold))
            }
            .foregroundStyle(isSelected ? color : palette.grey2)
            .padding(.vertical, 5)
            .padding(.horizontal, 9)
            .background(isSelected ? UpdateMeta.tint(type, palette) : Color.clear)
            .clipShape(Capsule())
            .overlay(
                Capsule()
                    .strokeBorder(isSelected ? color : palette.grey6, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SBToggle

/// A 38x22 pill track with an 18pt knob, matching the prototype's toggle switches.
public struct SBToggle: View {
    @Binding var isOn: Bool

    @Environment(\.palette) private var palette

    private let trackWidth: CGFloat = 38
    private let trackHeight: CGFloat = 22
    private let knobSize: CGFloat = 18
    private let knobInset: CGFloat = 2

    public init(isOn: Binding<Bool>) { self._isOn = isOn }

    public var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                isOn.toggle()
            }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? palette.blue : palette.toggleOff)
                    .frame(width: trackWidth, height: trackHeight)

                Circle()
                    .fill(Color.white)
                    .frame(width: knobSize, height: knobSize)
                    .shadow(color: .black.opacity(0.3), radius: 3, x: 0, y: 1)
                    .padding(.horizontal, knobInset)
            }
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.2), value: isOn)
    }
}

// MARK: - SectionHeaderButton

/// Sidebar section header: chevron (rotates -90deg when collapsed) + uppercase label + count chip.
public struct SectionHeaderButton: View {
    let title: String
    let count: Int
    let isExpanded: Bool
    let action: () -> Void

    @Environment(\.palette) private var palette

    public init(title: String, count: Int, isExpanded: Bool, action: @escaping () -> Void) {
        self.title = title; self.count = count; self.isExpanded = isExpanded; self.action = action
    }

    public var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(palette.grey3)
                    .rotationEffect(.degrees(isExpanded ? 0 : -90))
                    .animation(.easeInOut(duration: 0.2), value: isExpanded)

                Text(title.uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .tracking(1)
                    .foregroundStyle(palette.grey2)

                Spacer()

                Text("\(count)")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(palette.grey3)
                    .padding(.vertical, 1)
                    .padding(.horizontal, 8)
                    .background(palette.chip)
                    .clipShape(Capsule())
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - IconButton

/// Square icon-only button using an SF Symbol, transparent by default with a hover background.
public struct IconButton: View {
    let systemName: String
    var size: CGFloat = 24
    var iconSize: CGFloat = 13
    var foreground: Color?
    var hoverBackground: Color?
    let action: () -> Void

    @Environment(\.palette) private var palette
    @State private var isHovering = false

    public init(systemName: String, size: CGFloat = 24, iconSize: CGFloat = 13,
                foreground: Color? = nil, hoverBackground: Color? = nil,
                action: @escaping () -> Void) {
        self.systemName = systemName; self.size = size; self.iconSize = iconSize
        self.foreground = foreground; self.hoverBackground = hoverBackground; self.action = action
    }

    public var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: iconSize, weight: .medium))
                .foregroundStyle(foreground ?? palette.grey3)
                .frame(width: size, height: size)
                .background(isHovering ? (hoverBackground ?? palette.hover) : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
