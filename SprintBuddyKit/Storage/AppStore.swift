//
//  AppStore.swift
//  SprintBuddyKit
//
//  Shared access points for the main app and the menu-bar agent: one SwiftData
//  store and one preferences suite. Both processes are UNsandboxed (Pulse-style
//  distribution: no sandbox -> no provisioning profile -> no 7-day expiry, and
//  SMAppService login items work with plain team signing), so they share plain
//  user-domain paths:
//
//    store  ~/Library/Application Support/SprintBuddy/SprintBuddy.store
//    prefs  UserDefaults suite "com.hadiyarajesh.sprintbuddy.shared"
//
//  Earlier sandboxed builds kept both in the App Group container; a one-time
//  migration below copies that data forward on first launch.
//

import Foundation
import SwiftData

public enum AppGroup {
    /// Legacy App Group id — only used to find pre-refactor data to migrate.
    public static let identifier = "group.com.hadiyarajesh.sprintbuddy"

    /// Preferences shared across both processes (theme, recap settings, …).
    public static let defaults: UserDefaults = {
        let suite = UserDefaults(suiteName: "com.hadiyarajesh.sprintbuddy.shared") ?? .standard
        migrateLegacyPrefsIfNeeded(into: suite)
        return suite
    }()

    /// Root of the legacy sandboxed App Group container (may not exist).
    static var legacyContainerURL: URL {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent("Library/Group Containers/\(identifier)", isDirectory: true)
    }

    /// Copy the pre-refactor preferences (theme, recap time, selections, …)
    /// out of the App Group suite the first time the new suite is used.
    private static func migrateLegacyPrefsIfNeeded(into suite: UserDefaults) {
        let marker = "didMigrateLegacyGroupPrefs"
        guard !suite.bool(forKey: marker) else { return }
        suite.set(true, forKey: marker)
        let plist = legacyContainerURL
            .appendingPathComponent("Library/Preferences/\(identifier).plist")
        guard let legacy = NSDictionary(contentsOf: plist) as? [String: Any] else { return }
        for (key, value) in legacy where suite.object(forKey: key) == nil {
            suite.set(value, forKey: key)
        }
    }
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

    /// `~/Library/Application Support/SprintBuddy` — shared by both processes
    /// now that neither is sandboxed.
    static var storeDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SprintBuddy", isDirectory: true)
    }

    static var storeURL: URL { storeDirectory.appendingPathComponent("SprintBuddy.store") }

    /// A `ModelContainer` on the shared store. On failure (corrupt/unmigratable
    /// store) it falls back to an in-memory store so the app still opens instead
    /// of crash-looping — the on-disk file is left untouched for recovery.
    public static func container() -> ModelContainer {
        migrateLegacyStoreIfNeeded()
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
        try? FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        return ModelConfiguration(schema: schema, url: storeURL)
    }

    /// Copy the store out of the legacy sandboxed App Group container the
    /// first time the new location is used (store + SQLite -shm/-wal sidecars,
    /// so uncheckpointed writes aren't lost). The legacy files are left in
    /// place as a backup.
    private static func migrateLegacyStoreIfNeeded() {
        let fm = FileManager.default
        guard !fm.fileExists(atPath: storeURL.path) else { return }
        let legacyStore = AppGroup.legacyContainerURL.appendingPathComponent("SprintBuddy.store")
        guard fm.fileExists(atPath: legacyStore.path) else { return }
        try? fm.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        do {
            for suffix in ["", "-shm", "-wal"] {
                let src = URL(fileURLWithPath: legacyStore.path + suffix)
                guard fm.fileExists(atPath: src.path) else { continue }
                try fm.copyItem(at: src, to: URL(fileURLWithPath: storeURL.path + suffix))
            }
            NSLog("[SprintBuddy] Migrated store from the legacy App Group container.")
        } catch {
            NSLog("[SprintBuddy] Legacy store migration failed: \(error)")
        }
    }
}
