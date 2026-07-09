//
//  SprintBuddyApp.swift
//  SprintBuddy
//
//  Created by Rajesh Hadiya on 08/07/26.
//

import SwiftData
import SwiftUI
import AppKit
import UserNotifications

/// Keeps the app running in the menu bar after the main window is closed, so
/// the quick-logger stays available ("always-on"). ⌘Q still quits normally.
/// Also routes the daily-recap notification (foreground display + tap-to-open).
final class AppDelegate: NSObject, NSApplicationDelegate, UNUserNotificationCenterDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    // Show the recap even when SprintBuddy is the frontmost app.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    // Tapping the notification brings the main window forward.
    @MainActor
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse) async {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first(where: { $0.canBecomeMain })?.makeKeyAndOrderFront(nil)
    }
}

@main
struct SprintBuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    /// One shared container so the main window and the menu-bar quick-logger
    /// read and write the same store.
    let modelContainer: ModelContainer

    init() {
        do {
            modelContainer = try ModelContainer(for: Sprint.self, Day.self, DayUpdate.self)
        } catch {
            fatalError("Failed to create the SprintBuddy model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView()
        }
        .modelContainer(modelContainer)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 1240, height: 820)

        MenuBarExtra("SprintBuddy", systemImage: "checklist") {
            QuickEntryView()
                .modelContainer(modelContainer)
        }
        .menuBarExtraStyle(.window)
    }
}
