//
//  SprintBuddyApp.swift
//  SprintBuddy
//
//  The main (windowed) app. It also owns the embedded menu-bar agent
//  (Contents/Library/LoginItems/SprintBuddyMenuBar.app): on launch it registers
//  the agent as a login item and starts it if it isn't already running. The
//  agent is a separate process, so ⌘Q here quits only the window app — the menu
//  bar keeps running. Both share one App-Group SwiftData store; cross-process
//  changes are signaled via DataSync and applied by StoreRefresher.
//

import SwiftUI
import SwiftData
import SprintBuddyKit
import AppKit
import UserNotifications

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Register + launch the menu-bar agent if "Show in Menu Bar" is on.
        AgentController.syncOnLaunch()
        // The agent owns the recap notification since the process split, but a
        // pre-split version scheduled repeating notifications from THIS bundle;
        // such a fossil re-delivers its frozen content daily forever. Nothing
        // is ever legitimately pending here, so sweep unconditionally.
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        // A new window makes its first text field — the sprint name — first
        // responder with the text selected, so one stray keystroke would
        // rename the sprint. Start each main window with nothing focused. The
        // launch window is already key by now, so handle existing windows too.
        keyObserver = NotificationCenter.default.addObserver(
            forName: NSWindow.didBecomeKeyNotification, object: nil, queue: .main
        ) { [weak self] note in
            (note.object as? NSWindow).map { self?.clearInitialFocus($0) }
        }
        NSApp.windows.filter(\.isKeyWindow).forEach(clearInitialFocus)
    }

    private var keyObserver: NSObjectProtocol?
    private var unfocusedWindows = Set<ObjectIdentifier>()

    /// Once per main window. Sheets are skipped: focusing their first field is wanted.
    private func clearInitialFocus(_ window: NSWindow) {
        guard window.canBecomeMain, window.sheetParent == nil,
              unfocusedWindows.insert(ObjectIdentifier(window)).inserted else { return }
        DispatchQueue.main.async { window.makeFirstResponder(nil) }
    }

    func applicationDidResignActive(_ notification: Notification) {
        // Catch-all for edits persisted by SwiftData's autosave (e.g. the
        // sprint name/focus TextFields), which never go through
        // SprintStore.save and so post no change signal of their own.
        DataSync.postDidSave()
    }
}

@main
struct SprintBuddyApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    // Owned here (not in ContentView) so it survives store reloads below.
    @StateObject private var appState = AppState()
    @StateObject private var store = StoreRefresher.shared

    var body: some Scene {
        WindowGroup(id: "main") {
            ContentView(appState: appState)
                .id(store.generation)
                .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
                    // Apply a reload deferred because the agent saved while this
                    // app was active (StoreRefresher reloads immediately when
                    // the app is in the background, so the visible board updates
                    // live). AppState is retained above, so selection survives
                    // the rebuild.
                    store.reloadIfNeeded()
                }
        }
        .modelContainer(store.container)
        .windowStyle(.hiddenTitleBar)
        .windowToolbarStyle(.unifiedCompact)
        .defaultSize(width: 1240, height: 820)
    }
}
