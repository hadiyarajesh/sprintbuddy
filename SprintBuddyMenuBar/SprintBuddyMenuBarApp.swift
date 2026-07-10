//
//  SprintBuddyMenuBarApp.swift
//  SprintBuddyMenuBar
//
//  The resident menu-bar agent (LSUIElement, no Dock icon). Hosts the
//  quick-logger + "Recent" recap and owns the daily recap notification. Shares
//  the App-Group SwiftData store with the main app, so it keeps working after
//  the main app is quit.
//

import SwiftUI
import SwiftData
import SprintBuddyKit
import AppKit
import UserNotifications

let mainAppBundleID = BundleID.mainApp

/// Launches (or brings forward) the main windowed app.
@MainActor
func openMainApp() {
    NSApp.activate(ignoringOtherApps: true)
    if let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: mainAppBundleID) {
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }
}

final class MenuBarAppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    /// Shared store, used both by the MenuBarExtra scene and to compute recap content.
    let container = AppStore.container()

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        // Login registration is owned by the main app (it registers this
        // embedded helper via SMAppService.loginItem).
        rescheduleRecap()
        NotificationCenter.default.addObserver(
            self, selector: #selector(appBecameActive),
            name: NSApplication.didBecomeActiveNotification, object: nil
        )
    }

    @objc private func appBecameActive() { rescheduleRecap() }

    /// Recompute the notification content from the shared store.
    @MainActor
    private func rescheduleRecap() {
        let sprints = (try? container.mainContext.fetch(FetchDescriptor<Sprint>())) ?? []
        RecapNotifier.refresh(sprints: sprints.map { $0.toDTO() })
    }

    // Show the recap even when the agent is frontmost.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    // Tapping the recap opens the main app.
    @MainActor
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        openMainApp()
    }
}

@main
struct SprintBuddyMenuBarApp: App {
    @NSApplicationDelegateAdaptor(MenuBarAppDelegate.self) private var delegate

    var body: some Scene {
        MenuBarExtra("SprintBuddy", systemImage: "checklist") {
            QuickEntryView()
                .modelContainer(delegate.container)
        }
        .menuBarExtraStyle(.window)
    }
}
