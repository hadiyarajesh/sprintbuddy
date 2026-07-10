//
//  AgentController.swift
//  SprintBuddy
//
//  Manages the embedded menu-bar agent from the main app: the "Show in Menu
//  Bar" preference (default on) controls whether the agent is registered as a
//  login item and running. Turning it off unregisters the login item and quits
//  the agent process; turning it on registers and launches it.
//

import Foundation
import AppKit
import ServiceManagement
import SprintBuddyKit

enum AgentController {
    static let agentBundleID = "com.hadiyarajesh.SprintBuddyMenuBar"
    private static let key = "showInMenuBar"

    /// Whether the menu-bar agent should be present. Defaults to `true` (on) the
    /// first time, so a fresh install shows the menu bar.
    static var isEnabled: Bool {
        (AppGroup.defaults.object(forKey: key) as? Bool) ?? true
    }

    /// Apply the current preference at app launch.
    static func syncOnLaunch() {
        if isEnabled { enable() } else { disable() }
    }

    /// Persist the preference and apply it immediately.
    static func setEnabled(_ on: Bool) {
        AppGroup.defaults.set(on, forKey: key)
        if on { enable() } else { disable() }
    }

    // MARK: - Apply

    private static func enable() {
        try? SMAppService.loginItem(identifier: agentBundleID).register()
        launchAgentIfNeeded()
    }

    private static func disable() {
        try? SMAppService.loginItem(identifier: agentBundleID).unregister()
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: agentBundleID) {
            app.terminate()
        }
    }

    /// Starts the embedded agent now (without stealing focus) if it isn't running.
    private static func launchAgentIfNeeded() {
        guard NSRunningApplication.runningApplications(withBundleIdentifier: agentBundleID).isEmpty else { return }
        let agentURL = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Library/LoginItems/SprintBuddyMenuBar.app")
        guard FileManager.default.fileExists(atPath: agentURL.path) else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = false
        NSWorkspace.shared.openApplication(at: agentURL, configuration: config)
    }
}
