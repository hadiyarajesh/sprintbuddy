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
        didSet { defaults.set(selectedSprintID, forKey: PrefKey.selectedSprintID) }
    }
    @Published var selectedDateISO: String? {
        didSet { defaults.set(selectedDateISO, forKey: PrefKey.selectedDateISO) }
    }
    @Published var paneCollapsed: Bool {
        didSet { defaults.set(paneCollapsed, forKey: PrefKey.paneCollapsed) }
    }
    @Published var activeOpen: Bool {
        didSet { defaults.set(activeOpen, forKey: PrefKey.activeOpen) }
    }
    @Published var archiveOpen: Bool {
        didSet { defaults.set(archiveOpen, forKey: PrefKey.archiveOpen) }
    }

    // MARK: - Persisted prefs (shared with the agent via the App-Group suite)

    @Published var theme: String {
        didSet { defaults.set(theme, forKey: PrefKey.theme) }
    }
    @Published var showWeekends: Bool {
        didSet { defaults.set(showWeekends, forKey: PrefKey.showWeekends) }
    }
    @Published var highlightUnlogged: Bool {
        didSet { defaults.set(highlightUnlogged, forKey: PrefKey.highlightUnlogged) }
    }
    /// When on, selecting a day card opens the detail pane; when off, the pane
    /// only opens via the collapsed opener strip.
    @Published var autoOpenDetail: Bool {
        didSet { defaults.set(autoOpenDetail, forKey: PrefKey.autoOpenDetail) }
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
        selectedSprintID = d.string(forKey: PrefKey.selectedSprintID)
        selectedDateISO = d.string(forKey: PrefKey.selectedDateISO)
        paneCollapsed = (d.object(forKey: PrefKey.paneCollapsed) as? Bool) ?? false
        activeOpen = (d.object(forKey: PrefKey.activeOpen) as? Bool) ?? true
        archiveOpen = (d.object(forKey: PrefKey.archiveOpen) as? Bool) ?? true
        theme = d.string(forKey: PrefKey.theme) ?? "auto"
        showWeekends = (d.object(forKey: PrefKey.showWeekends) as? Bool) ?? true
        highlightUnlogged = (d.object(forKey: PrefKey.highlightUnlogged) as? Bool) ?? true
        autoOpenDetail = (d.object(forKey: PrefKey.autoOpenDetail) as? Bool) ?? true
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
}
