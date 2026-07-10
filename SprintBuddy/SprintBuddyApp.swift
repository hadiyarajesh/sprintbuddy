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

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register + launch the menu-bar agent if "Show in Menu Bar" is on.
        AgentController.syncOnLaunch()
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
