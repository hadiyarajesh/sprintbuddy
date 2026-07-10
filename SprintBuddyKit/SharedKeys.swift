//
//  SharedKeys.swift
//  SprintBuddyKit
//
//  The cross-process contract between the main app and the menu-bar agent:
//  bundle identifiers and the shared UserDefaults keys. Centralized here so a
//  typo in one process can't silently break data/preference sharing.
//

import Foundation

public enum BundleID {
    public static let mainApp = "com.hadiyarajesh.SprintBuddy"
    public static let agent = "com.hadiyarajesh.SprintBuddyMenuBar"
}

/// Keys used in the App-Group `UserDefaults` suite (`AppGroup.defaults`).
public enum PrefKey {
    // Preferences shared with the agent
    public static let theme = "theme"
    public static let showWeekends = "showWeekends"
    public static let highlightUnlogged = "highlightUnlogged"
    public static let recapEnabled = "recapEnabled"
    public static let recapHour = "recapHour"
    public static let recapMinute = "recapMinute"
    public static let showInMenuBar = "showInMenuBar"

    // Main-app UI state (not read by the agent, but stored in the same suite)
    public static let selectedSprintID = "selectedSprintID"
    public static let selectedDateISO = "selectedDateISO"
    public static let paneCollapsed = "paneCollapsed"
    public static let activeOpen = "activeOpen"
    public static let archiveOpen = "archiveOpen"
    public static let autoOpenDetail = "autoOpenDetail"
}
