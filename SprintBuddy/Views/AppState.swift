//
//  AppState.swift
//  SprintBuddy
//
//  Central UI/selection state for the app shell. Durable selection/UI state
//  (selected sprint/date, pane collapse, sidebar section expansion) and the
//  three user prefs (theme, showWeekends, highlightUnlogged) are mirrored to
//  `UserDefaults` on `didSet` and reloaded in `init()`, so they survive
//  relaunches. Sheet/popover flags are transient (not persisted).
//
//  Design note: the task brief suggested prefs could live behind `@AppStorage`
//  wrappers, but `@AppStorage` does not participate in `ObservableObject`
//  publishing — a view reading `appState.theme` would not re-render when the
//  value changes elsewhere. Since `.preferredColorScheme` must react live to
//  a theme change (e.g. from a future Settings sheet), `theme` (and, for
//  consistency, `showWeekends`/`highlightUnlogged`) are kept as plain
//  `@Published` properties mirrored to `UserDefaults` in `didSet`, exactly
//  like the other persisted fields below.
//

import Combine
import SwiftUI

final class AppState: ObservableObject {

    // MARK: - Persisted selection / UI state

    @Published var selectedSprintID: String? {
        didSet { UserDefaults.standard.set(selectedSprintID, forKey: Keys.selectedSprintID) }
    }
    @Published var selectedDateISO: String? {
        didSet { UserDefaults.standard.set(selectedDateISO, forKey: Keys.selectedDateISO) }
    }
    @Published var paneCollapsed: Bool {
        didSet { UserDefaults.standard.set(paneCollapsed, forKey: Keys.paneCollapsed) }
    }
    @Published var activeOpen: Bool {
        didSet { UserDefaults.standard.set(activeOpen, forKey: Keys.activeOpen) }
    }
    @Published var archiveOpen: Bool {
        didSet { UserDefaults.standard.set(archiveOpen, forKey: Keys.archiveOpen) }
    }

    // MARK: - Persisted prefs (see design note above re: not using @AppStorage here)

    @Published var theme: String {
        didSet { UserDefaults.standard.set(theme, forKey: Keys.theme) }
    }
    @Published var showWeekends: Bool {
        didSet { UserDefaults.standard.set(showWeekends, forKey: Keys.showWeekends) }
    }
    @Published var highlightUnlogged: Bool {
        didSet { UserDefaults.standard.set(highlightUnlogged, forKey: Keys.highlightUnlogged) }
    }

    /// Daily recap notification: opt-in, at `recapHour`:`recapMinute` local time.
    /// (`RecapNotifier` reads these same UserDefaults keys.)
    @Published var recapEnabled: Bool {
        didSet { UserDefaults.standard.set(recapEnabled, forKey: Keys.recapEnabled) }
    }
    @Published var recapHour: Int {
        didSet { UserDefaults.standard.set(recapHour, forKey: Keys.recapHour) }
    }
    @Published var recapMinute: Int {
        didSet { UserDefaults.standard.set(recapMinute, forKey: Keys.recapMinute) }
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
        let d = UserDefaults.standard
        selectedSprintID = d.string(forKey: Keys.selectedSprintID)
        selectedDateISO = d.string(forKey: Keys.selectedDateISO)
        paneCollapsed = (d.object(forKey: Keys.paneCollapsed) as? Bool) ?? false
        activeOpen = (d.object(forKey: Keys.activeOpen) as? Bool) ?? true
        archiveOpen = (d.object(forKey: Keys.archiveOpen) as? Bool) ?? true
        theme = d.string(forKey: Keys.theme) ?? "auto"
        showWeekends = (d.object(forKey: Keys.showWeekends) as? Bool) ?? true
        highlightUnlogged = (d.object(forKey: Keys.highlightUnlogged) as? Bool) ?? true
        recapEnabled = (d.object(forKey: Keys.recapEnabled) as? Bool) ?? false
        recapHour = (d.object(forKey: Keys.recapHour) as? Int) ?? 10
        recapMinute = (d.object(forKey: Keys.recapMinute) as? Int) ?? 0
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
        static let recapEnabled = "recapEnabled"
        static let recapHour = "recapHour"
        static let recapMinute = "recapMinute"
    }
}
