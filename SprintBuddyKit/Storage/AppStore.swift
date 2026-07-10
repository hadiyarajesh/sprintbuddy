//
//  AppStore.swift
//  SprintBuddyKit
//
//  Shared access points for the main app and the menu-bar agent: one SwiftData
//  store and one preferences suite, both living in the App Group container so
//  both processes read and write the same data.
//

import Foundation
import SwiftData

public enum AppGroup {
    public static let identifier = "group.com.hadiyarajesh.sprintbuddy"

    /// Preferences shared across both processes (theme, recap settings, …).
    public static let defaults: UserDefaults = UserDefaults(suiteName: identifier) ?? .standard
}

public enum AppStore {
    /// A `ModelContainer` backed by the App Group container so the main app and
    /// the agent share one store. Falls back to the default location if the
    /// group container can't be resolved (e.g. entitlement missing in a preview).
    public static func container() -> ModelContainer {
        let schema = Schema([Sprint.self, Day.self, DayUpdate.self])
        let groupURL = FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier)

        let config: ModelConfiguration
        if let groupURL {
            let storeURL = groupURL.appendingPathComponent("SprintBuddy.store")
            config = ModelConfiguration(schema: schema, url: storeURL)
        } else {
            config = ModelConfiguration(schema: schema)
        }

        do {
            return try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create shared SprintBuddy ModelContainer: \(error)")
        }
    }
}
