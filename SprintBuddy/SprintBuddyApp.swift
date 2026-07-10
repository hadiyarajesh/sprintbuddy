//
//  SprintBuddyApp.swift
//  SprintBuddy
//
//  The main (windowed) app. The menu-bar quick-logger + daily recap now live
//  in the separate SprintBuddyMenuBar agent, so ⌘Q here quits only this window
//  app — the agent keeps running. Both share one App-Group SwiftData store.
//

import SwiftUI
import SwiftData
import SprintBuddyKit

@main
struct SprintBuddyApp: App {
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
