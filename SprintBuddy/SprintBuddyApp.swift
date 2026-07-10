//
//  SprintBuddyApp.swift
//  SprintBuddy
//
//  The main (windowed) app. It also owns the embedded menu-bar agent
//  (Contents/Library/LoginItems/SprintBuddyMenuBar.app): on launch it registers
//  the agent as a login item and starts it if it isn't already running. The
//  agent is a separate process, so ⌘Q here quits only the window app — the menu
//  bar keeps running. Both share one App-Group SwiftData store.
//

import SwiftUI
import SwiftData
import SprintBuddyKit
import AppKit
import ServiceManagement

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let agentBundleID = "com.hadiyarajesh.SprintBuddyMenuBar"

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register the embedded helper to launch at login (idempotent).
        try? SMAppService.loginItem(identifier: agentBundleID).register()
        launchAgentIfNeeded()
    }

    /// Starts the embedded agent now (so the menu bar appears without waiting
    /// for the next login), without stealing focus from the main window.
    private func launchAgentIfNeeded() {
        guard NSRunningApplication.runningApplications(withBundleIdentifier: agentBundleID).isEmpty else { return }
        let agentURL = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Library/LoginItems/SprintBuddyMenuBar.app")
        guard FileManager.default.fileExists(atPath: agentURL.path) else { return }
        let config = NSWorkspace.OpenConfiguration()
        config.activates = false
        NSWorkspace.shared.openApplication(at: agentURL, configuration: config)
    }
}

@main
struct SprintBuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    private let modelContainer = AppStore.container()

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
        }
        .modelContainer(modelContainer)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 1240, height: 820)
    }
}
