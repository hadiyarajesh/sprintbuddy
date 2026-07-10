//
//  AppInfo.swift
//  SprintBuddyKit
//
//  Small bundle-info helpers shared by both apps.
//

import Foundation

public enum AppInfo {
    /// The app's marketing version (CFBundleShortVersionString), e.g. "1.0".
    public static var version: String {
        (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String) ?? "1.0"
    }

    /// A display string like "v1.0".
    public static var displayVersion: String { "v\(version)" }
}
