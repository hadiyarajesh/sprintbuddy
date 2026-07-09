//
//  SprintBuddyApp.swift
//  SprintBuddy
//
//  Created by Rajesh Hadiya on 08/07/26.
//

import SwiftData
import SwiftUI

@main
struct SprintBuddyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Sprint.self, Day.self, DayUpdate.self])
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 1240, height: 820)
    }
}
