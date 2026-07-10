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
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
        // Login registration is owned by the main app (it registers this
        // embedded helper via SMAppService.loginItem).
        MainActor.assumeIsolated {
            // When the main app saves, StoreRefresher reloads our container —
            // recompute the recap from the fresh data too.
            StoreRefresher.shared.onReload = { [weak self] in self?.rescheduleRecap() }
            rescheduleRecap()
        }
        NotificationCenter.default.addObserver(
            self, selector: #selector(appBecameActive),
            name: NSApplication.didBecomeActiveNotification, object: nil
        )
    }

    @objc private func appBecameActive() {
        MainActor.assumeIsolated {
            // Opening the panel activates the agent: apply any reload deferred
            // while the panel was open, then refresh the recap.
            StoreRefresher.shared.reloadIfNeeded()
            rescheduleRecap()
        }
    }

    /// Recompute the notification content from the shared store.
    @MainActor
    private func rescheduleRecap() {
        let context = StoreRefresher.shared.container.mainContext
        let sprints = (try? context.fetch(FetchDescriptor<Sprint>())) ?? []
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
    @StateObject private var store = StoreRefresher.shared

    var body: some Scene {
        MenuBarExtra("SprintBuddy", systemImage: "checklist") {
            QuickEntryView()
                .id(store.generation)
                .modelContainer(store.container)
        }
        .menuBarExtraStyle(.window)
    }
}
