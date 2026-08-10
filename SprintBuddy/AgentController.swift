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
    static let agentBundleID = BundleID.agent
    private static let key = PrefKey.showInMenuBar

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
        if on { enable(userInitiated: true) } else { disable() }
    }

    private static var isAgentRunning: Bool {
        !NSRunningApplication.runningApplications(withBundleIdentifier: agentBundleID).isEmpty
    }

    // MARK: - Apply

    /// launchd (via `register()`) is the only reliable way to start the embedded
    /// login-item helper — `NSWorkspace` can't launch an app nested in
    /// `Contents/Library/LoginItems`. `register()` launches the helper only on
    /// the transition into `.enabled`, so when the agent should run but isn't,
    /// force that transition by re-registering. This is the single launch path,
    /// so no duplicate processes are spawned.
    private static func enable(userInitiated: Bool = false) {
        guard !isAgentRunning else { return }
        let service = SMAppService.loginItem(identifier: agentBundleID)
        // Best-effort only: a stale registration (e.g. left by another app copy
        // whose bundle no longer exists) can make unregister throw — that must
        // never abort the register below, so keep it out of the do/catch.
        if service.status == .enabled {
            try? service.unregister()
        }
        do {
            try service.register()
        } catch {
            NSLog("[SprintBuddy] Failed to register menu-bar agent login item: \(error)")
        }
        // If the user switched the login item off in System Settings, the app
        // cannot re-enable it programmatically — take them to the switch (only
        // when they explicitly toggled, never on plain app launch).
        if service.status == .requiresApproval, userInitiated {
            SMAppService.openSystemSettingsLoginItems()
        }
    }

    private static func disable() {
        do {
            try SMAppService.loginItem(identifier: agentBundleID).unregister()
        } catch {
            NSLog("[SprintBuddy] Failed to unregister menu-bar agent login item: \(error)")
        }
        for app in NSRunningApplication.runningApplications(withBundleIdentifier: agentBundleID) {
            app.terminate()
        }
    }
}
