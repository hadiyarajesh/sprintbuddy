//
//  DataSync.swift
//  SprintBuddyKit
//
//  Cross-process change signaling between the main app and the menu-bar agent.
//  SwiftData gives a @Query no notification when *another process* writes to
//  the shared App-Group store, so the writer posts a Darwin notification after
//  each save and the other process reloads its container (see StoreRefresher).
//  Darwin notifications are name-only (no payload) and work across sandboxed
//  processes in the same App Group.
//

import Foundation

public enum DataSync {
    private static let prefix = "com.hadiyarajesh.sprintbuddy.didSave."

    private static var isAgent: Bool { Bundle.main.bundleIdentifier == BundleID.agent }
    /// Each process posts under its own role name and listens for the other's,
    /// so a process never reacts to its own saves.
    private static var postName: String { prefix + (isAgent ? "agent" : "main") }
    private static var observeName: String { prefix + (isAgent ? "main" : "agent") }

    nonisolated(unsafe) private static var handler: (() -> Void)?
    nonisolated(unsafe) private static var registered = false

    /// Tell the other SprintBuddy process that the shared store changed.
    public static func postDidSave() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(postName as CFString),
            nil, nil, true
        )
    }

    /// Invoke `onChange` (on the main queue) whenever the *other* SprintBuddy
    /// process saves to the shared store. The observer lives for the process
    /// lifetime; calling again just replaces the handler.
    public static func observeRemoteSaves(_ onChange: @escaping () -> Void) {
        handler = onChange
        guard !registered else { return }
        registered = true
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            { _, _, _, _, _ in
                DispatchQueue.main.async { DataSync.handler?() }
            },
            observeName as CFString,
            nil,
            .deliverImmediately
        )
    }
}
