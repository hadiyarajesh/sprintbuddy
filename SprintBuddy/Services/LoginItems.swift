//
//  LoginItems.swift
//  SprintBuddy
//
//  Thin wrapper over `SMAppService.mainApp` for the "Launch at login" setting.
//  `SMAppService` handles the sandbox-friendly login-item registration on
//  macOS 13+, so no extra entitlement is required.
//

import Foundation
import ServiceManagement

enum LoginItems {
    /// Whether the app is currently registered to launch at login.
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Registers or unregisters the app as a login item. Best-effort: on
    /// failure the real `SMAppService` status stays the source of truth, so
    /// callers should re-read `isEnabled` afterwards to reflect the result.
    static func setEnabled(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            // Ignored — `isEnabled` reflects the actual resulting state.
        }
    }
}
