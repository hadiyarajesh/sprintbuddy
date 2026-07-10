//
//  Theme.swift
//  SprintBuddyKit
//
//  Design tokens ported from the ScrumBuddy HTML prototype (`:root` and the
//  `html[data-sb-theme="dark"]` blocks) plus the design-system color tokens.
//

import SwiftUI

// MARK: - Color helpers

extension Color {
    /// Creates a `Color` from a 6-digit hex string (with or without a leading `#`).
    public init(hex: String) {
        var hexString = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexString = hexString.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexString).scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255.0
        let g = Double((rgb & 0x00FF00) >> 8) / 255.0
        let b = Double(rgb & 0x0000FF) / 255.0

        self = Color(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    /// Creates a `Color` from 0-255 RGB components and a 0-1 opacity, mirroring CSS `rgba(r, g, b, a)`.
    public static func rgba(_ r: Double, _ g: Double, _ b: Double, _ a: Double) -> Color {
        Color(.sRGB, red: r / 255.0, green: g / 255.0, blue: b / 255.0, opacity: a)
    }
}

// MARK: - Radius

/// Corner radii used across the app.
public enum Radius {
    public static let md: CGFloat = 9
    public static let lg: CGFloat = 14
    public static let card: CGFloat = 18
    public static let cell: CGFloat = 14
    public static let pill: CGFloat = 999
}

// MARK: - SBPalette

/// Resolved color palette for the current `ColorScheme`.
public struct SBPalette {
    public let scheme: ColorScheme

    // Brand
    public let blue: Color
    public let navy: Color
    public let textNavy: Color
    public let ink: Color

    // Greys (1 = darkest text-ish grey ... 6 = lightest border-ish grey)
    public let grey1: Color
    public let grey2: Color
    public let grey3: Color
    public let grey4: Color
    public let grey5: Color
    public let grey6: Color

    // Semantic
    public let error: Color
    public let success: Color
    public let successDark: Color
    public let warning: Color

    // Surfaces
    public let white: Color
    public let sidebar: Color
    public let boardTop: Color
    public let boardBottom: Color
    public let border: Color
    public let border2: Color
    public let chip: Color
    public let hover: Color
    public let hover2: Color
    public let navActive: Color
    public let todayBg: Color
    public let inputSoft: Color
    public let muted: Color
    public let toggleOff: Color
    public let scrollbar: Color
    public let scrollbarHover: Color

    // Tints / borders
    public let blueTint: Color
    public let blueTintBorder: Color
    public let redTint: Color
    public let redTintBorder: Color
    public let amberTint: Color
    public let amberTintBorder: Color
    public let greenTint: Color
    public let dashed: Color
    public let dashedWarn: Color
    public let cardBorder: Color
    public let cardBorder2: Color
    public let leaveBorder: Color
    public let holidayBorder: Color
    public let weekendBorder: Color

    // Fixed-across-themes tokens (per prototype)
    public let holidayText: Color = Color(hex: "b97907")

    // Window chrome shadow tokens (`--sb-window-shadow`)
    public let windowShadowBorder: Color
    public let windowShadowColor: Color

    public init(_ scheme: ColorScheme) {
        self.scheme = scheme
        let isDark = scheme == .dark

        blue = Color(hex: "2a76e1")
        navy = Color(hex: "18407b")
        textNavy = isDark ? Color(hex: "e6ebf5") : Color(hex: "263271")
        ink = isDark ? Color(hex: "f0f3fa") : Color(hex: "222222")

        grey1 = isDark ? Color(hex: "b8c2d4") : Color(hex: "666666")
        grey2 = isDark ? Color(hex: "98a3b7") : Color(hex: "757575")
        grey3 = isDark ? Color(hex: "727e94") : Color(hex: "9d9d9d")
        grey4 = isDark ? Color(hex: "5b6578") : Color(hex: "a5a5a5")
        grey5 = isDark ? Color(hex: "3a4152") : Color(hex: "bababa")
        grey6 = isDark ? Color(hex: "333a49") : Color(hex: "d4d4d4")

        error = Color(hex: "de0606")
        success = Color(hex: "4eb55c")
        successDark = Color(hex: "379143")
        warning = Color(hex: "f8a213")

        white = isDark ? Color(hex: "1b202b") : Color(hex: "ffffff")
        sidebar = isDark ? Color(hex: "14181f") : Color(hex: "f7f9fc")
        boardTop = isDark ? Color(hex: "10141c") : Color(hex: "f2f5fa")
        boardBottom = isDark ? Color(hex: "0b0e14") : Color(hex: "e8edf5")
        border = isDark ? Color(hex: "282e3a") : Color(hex: "e9edf4")
        border2 = isDark ? Color(hex: "2f3542") : Color(hex: "e5e9f1")
        chip = isDark ? Color(hex: "232a37") : Color(hex: "eaeef5")
        hover = isDark ? Color(hex: "232a37") : Color(hex: "eef2f8")
        hover2 = isDark ? Color(hex: "222a3a") : Color(hex: "eaf1fd")
        navActive = isDark ? Color.rgba(42, 118, 225, 0.26) : Color(hex: "dce8fc")
        todayBg = isDark ? Color.rgba(42, 118, 225, 0.16) : Color(hex: "eaf2fe")
        inputSoft = isDark ? Color(hex: "12161f") : Color(hex: "fbfcfe")
        muted = isDark ? Color(hex: "1b212c") : Color(hex: "eef1f6")
        toggleOff = isDark ? Color(hex: "3a4152") : Color(hex: "cfd6e2")
        scrollbar = isDark ? Color(hex: "333a49") : Color(hex: "d3dbe8")
        scrollbarHover = isDark ? Color(hex: "3f4759") : Color(hex: "bcc7da")

        blueTint = isDark ? Color.rgba(42, 118, 225, 0.16) : Color(hex: "eef4fe")
        blueTintBorder = isDark ? Color.rgba(42, 118, 225, 0.4) : Color(hex: "d6e5fb")
        redTint = isDark ? Color.rgba(222, 6, 6, 0.2) : Color(hex: "fdeeee")
        redTintBorder = isDark ? Color.rgba(222, 6, 6, 0.45) : Color(hex: "f6d4d4")
        amberTint = isDark ? Color.rgba(248, 162, 19, 0.17) : Color(hex: "fef7eb")
        amberTintBorder = isDark ? Color.rgba(248, 162, 19, 0.45) : Color(hex: "f6e2bd")
        greenTint = isDark ? Color.rgba(78, 181, 92, 0.18) : Color(hex: "edfbf2")
        dashed = isDark ? Color(hex: "3b4353") : Color(hex: "cfd8e6")
        dashedWarn = isDark ? Color.rgba(248, 162, 19, 0.6) : Color(hex: "f0c675")
        cardBorder = isDark ? Color.rgba(255, 255, 255, 0.08) : Color.rgba(19, 19, 76, 0.06)
        cardBorder2 = isDark ? Color.rgba(255, 255, 255, 0.09) : Color.rgba(19, 19, 76, 0.08)
        leaveBorder = isDark ? Color.rgba(222, 6, 6, 0.4) : Color.rgba(222, 6, 6, 0.16)
        holidayBorder = isDark ? Color.rgba(248, 162, 19, 0.45) : Color.rgba(248, 162, 19, 0.22)
        weekendBorder = isDark ? Color(hex: "242a36") : Color(hex: "e4e8f0")

        windowShadowBorder = isDark ? Color.rgba(255, 255, 255, 0.07) : Color.rgba(19, 19, 76, 0.1)
        windowShadowColor = isDark ? Color.rgba(0, 0, 0, 0.72) : Color.rgba(19, 19, 76, 0.45)
    }

    /// The board background gradient (`--sb-board`), top-to-bottom.
    public var boardGradient: LinearGradient {
        LinearGradient(colors: [boardTop, boardBottom], startPoint: .top, endPoint: .bottom)
    }
}

// MARK: - Environment plumbing

private struct SBPaletteKey: EnvironmentKey {
    static let defaultValue = SBPalette(.light)
}

extension EnvironmentValues {
    public var palette: SBPalette {
        get { self[SBPaletteKey.self] }
        set { self[SBPaletteKey.self] = newValue }
    }
}

extension View {
    /// Injects an `SBPalette` into the environment for this view and its descendants.
    public func sbPalette(_ palette: SBPalette) -> some View {
        environment(\.palette, palette)
    }
}

// MARK: - UpdateMeta

/// Mirrors the prototype's `typeMeta()` helper: label/color/tint per `UpdateType`.
public enum UpdateMeta {
    public static func label(_ type: UpdateType) -> String {
        switch type {
        case .done: return "Done"
        case .doing: return "Doing"
        case .blocker: return "Blocker"
        }
    }

    public static func color(_ type: UpdateType, _ p: SBPalette) -> Color {
        switch type {
        case .done: return p.success
        case .doing: return p.blue
        case .blocker: return p.error
        }
    }

    public static func tint(_ type: UpdateType, _ p: SBPalette) -> Color {
        switch type {
        case .done: return p.greenTint
        case .doing: return p.blueTint
        case .blocker: return p.redTint
        }
    }
}
