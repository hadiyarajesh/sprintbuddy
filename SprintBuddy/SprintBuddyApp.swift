//
//  SprintBuddyApp.swift
//  SprintBuddy
//
//  Created by Rajesh Hadiya on 08/07/26.
//

import SwiftData
import SwiftUI
import AppKit

/// Keeps the app running in the menu bar after the main window is closed, so
/// the quick-logger stays available ("always-on"). ⌘Q still quits normally.
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
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
