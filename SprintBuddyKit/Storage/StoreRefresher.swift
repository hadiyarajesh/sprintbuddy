//
//  StoreRefresher.swift
//  SprintBuddyKit
//
//  Owns the process's ModelContainer and swaps in a fresh one when the *other*
//  SprintBuddy process saves to the shared store (signaled via DataSync).
//  A stale container's context serves cached objects and never re-reads rows
//  written by another process, so reloading the container is what actually
//  surfaces cross-process changes; bumping `generation` lets the hosting scene
//  rebuild its view tree (re-running any @Query) against the new container.
//
//  If a remote save arrives while this app is active (the user may be mid-
//  interaction — e.g. typing in the agent's composer), the reload is deferred:
//  call `reloadIfNeeded()` from a becomes-active hook to apply it.
//

import SwiftUI
import SwiftData
import AppKit
import Combine

@MainActor
public final class StoreRefresher: ObservableObject {
    public static let shared = StoreRefresher()

    /// Bumped on every reload — use as a view `.id` to re-run @Query.
    @Published public private(set) var generation = 0
    public private(set) var container: ModelContainer

    /// Called after each reload (e.g. the agent reschedules its recap).
    public var onReload: (() -> Void)?

    private var needsReload = false

    private init() {
        container = AppStore.container()
        DataSync.observeRemoteSaves { [weak self] in self?.remoteDidSave() }
    }

    private func remoteDidSave() {
        if NSApp.isActive {
            needsReload = true
        } else {
            reload()
        }
    }

    /// Apply a deferred reload (call when the app becomes active).
    public func reloadIfNeeded() {
        if needsReload { reload() }
    }

    public func reload() {
        needsReload = false
        container = AppStore.container()
        generation &+= 1
        onReload?()
    }
}
