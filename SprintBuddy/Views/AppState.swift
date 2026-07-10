//
//  AppState.swift
//  SprintBuddy
//
//  Central UI/selection state for the main app. Durable selection/UI state and
//  the view prefs are mirrored to the App-Group `UserDefaults` suite (shared
//  with the menu-bar agent) on `didSet` and reloaded in `init()`. Sheet/popover
//  flags are transient. The recap notification is owned by the agent, so its
//  prefs are not managed here.
//

import Combine
import SwiftUI
import SprintBuddyKit

final class AppState: ObservableObject {

    private let defaults = AppGroup.defaults

    // MARK: - Persisted selection / UI state

    @Published var selectedSprintID: String? {
        didSet { defaults.set(selectedSprintID, forKey: Keys.selectedSprintID) }
    }
    @Published var selectedDateISO: String? {
        didSet { defaults.set(selectedDateISO, forKey: Keys.selectedDateISO) }
    }
    @Published var paneCollapsed: Bool {
        didSet { defaults.set(paneCollapsed, forKey: Keys.paneCollapsed) }
    }
    @Published var activeOpen: Bool {
        didSet { defaults.set(activeOpen, forKey: Keys.activeOpen) }
    }
    @Published var archiveOpen: Bool {
        didSet { defaults.set(archiveOpen, forKey: Keys.archiveOpen) }
    }

    // MARK: - Persisted prefs (shared with the agent via the App-Group suite)

    @Published var theme: String {
        didSet { defaults.set(theme, forKey: Keys.theme) }
    }
    @Published var showWeekends: Bool {
        didSet { defaults.set(showWeekends, forKey: Keys.showWeekends) }
    }
    @Published var highlightUnlogged: Bool {
        didSet { defaults.set(highlightUnlogged, forKey: Keys.highlightUnlogged) }
    }

    // MARK: - Sheet / popover flags (transient, not persisted)

    @Published var newSprintOpen: Bool = false
    @Published var standupOpen: Bool = false
    @Published var deleteOpen: Bool = false
    @Published var importWarnOpen: Bool = false
    @Published var settingsOpen: Bool = false
    @Published var helpOpen: Bool = false
    @Published var statusMenuOpen: Bool = false

    // MARK: - Transient import/error state

    @Published var pendingImport: [SprintDTO]? = nil
    @Published var importError: String = ""

    // MARK: - Init

    init() {
        let d = AppGroup.defaults
        selectedSprintID = d.string(forKey: Keys.selectedSprintID)
        selectedDateISO = d.string(forKey: Keys.selectedDateISO)
        paneCollapsed = (d.object(forKey: Keys.paneCollapsed) as? Bool) ?? false
        activeOpen = (d.object(forKey: Keys.activeOpen) as? Bool) ?? true
        archiveOpen = (d.object(forKey: Keys.archiveOpen) as? Bool) ?? true
        theme = d.string(forKey: Keys.theme) ?? "auto"
        showWeekends = (d.object(forKey: Keys.showWeekends) as? Bool) ?? true
        highlightUnlogged = (d.object(forKey: Keys.highlightUnlogged) as? Bool) ?? true
    }

    // MARK: - Derived

    /// `auto` -> `nil` (follow system), `light` -> `.light`, `dark` -> `.dark`.
    var colorSchemePreference: ColorScheme? {
        switch theme {
        case "light": return .light
        case "dark": return .dark
        default: return nil
        }
    }

    // MARK: - Keys

    private enum Keys {
        static let selectedSprintID = "selectedSprintID"
        static let selectedDateISO = "selectedDateISO"
        static let paneCollapsed = "paneCollapsed"
        static let activeOpen = "activeOpen"
        static let archiveOpen = "archiveOpen"
        static let theme = "theme"
        static let showWeekends = "showWeekends"
        static let highlightUnlogged = "highlightUnlogged"
    }
}
