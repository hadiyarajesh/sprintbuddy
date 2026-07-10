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

/// Versioned schema so future model changes can migrate instead of crashing.
public enum SprintBuddySchemaV1: VersionedSchema {
    public static var versionIdentifier = Schema.Version(1, 0, 0)
    public static var models: [any PersistentModel.Type] { [Sprint.self, Day.self, DayUpdate.self] }
}

/// One stage per released schema version. V1 is the baseline (no stages yet).
public enum SprintBuddyMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] { [SprintBuddySchemaV1.self] }
    public static var stages: [MigrationStage] { [] }
}

public enum AppStore {
    private static let schema = Schema(versionedSchema: SprintBuddySchemaV1.self)

    /// A `ModelContainer` backed by the App Group container so the main app and
    /// the agent share one store. On failure (corrupt/unmigratable store) it
    /// falls back to an in-memory store so the app still opens instead of
    /// crash-looping — the on-disk file is left untouched for recovery.
    public static func container() -> ModelContainer {
        let onDisk = configuration(inMemory: false)
        do {
            return try ModelContainer(for: schema, migrationPlan: SprintBuddyMigrationPlan.self, configurations: onDisk)
        } catch {
            NSLog("[SprintBuddy] On-disk ModelContainer failed (\(error)); falling back to in-memory.")
            let inMemory = configuration(inMemory: true)
            do {
                return try ModelContainer(for: schema, configurations: inMemory)
            } catch {
                fatalError("[SprintBuddy] In-memory ModelContainer also failed: \(error)")
            }
        }
    }

    private static func configuration(inMemory: Bool) -> ModelConfiguration {
        if inMemory {
            return ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        }
        if let groupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: AppGroup.identifier) {
            return ModelConfiguration(schema: schema, url: groupURL.appendingPathComponent("SprintBuddy.store"))
        }
        // No group container (e.g. entitlement missing in a preview) — default location.
        return ModelConfiguration(schema: schema)
    }
}
