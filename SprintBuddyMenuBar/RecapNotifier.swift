//
//  RecapNotifier.swift
//  SprintBuddyMenuBar
//
//  Owned by the agent: schedules the opt-in daily "standup recap" local
//  notification. Content (the previous day's updates, or a nudge when nothing
//  was logged) is baked in at schedule time and refreshed on the agent's
//  launch / activation, after any save in either app (Darwin signal), and at
//  midnight. Reads its prefs from the shared defaults suite.
//

import Foundation
import UserNotifications
import SprintBuddyKit

enum RecapNotifier {
    private static let identifier = "daily-recap"
    private static var center: UNUserNotificationCenter { .current() }

    private static var enabled: Bool { AppGroup.defaults.bool(forKey: PrefKey.recapEnabled) }
    private static var hour: Int { (AppGroup.defaults.object(forKey: PrefKey.recapHour) as? Int) ?? 10 }
    private static var minute: Int { (AppGroup.defaults.object(forKey: PrefKey.recapMinute) as? Int) ?? 0 }

    /// Prompts for notification permission. Returns whether it's now allowed.
    @discardableResult
    static func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    /// (Re)schedules the daily recap from current prefs + data, or cancels it
    /// when the setting is off or permission isn't granted.
    static func refresh(sprints: [SprintDTO]) {
        guard enabled else { cancel(); return }
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                schedule(sprints: sprints)
            default:
                cancel()
            }
        }
    }

    static func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    private static func schedule(sprints: [SprintDTO]) {
        // Recap strictly the previous day: show what was logged yesterday, or a
        // "nothing logged yesterday" nudge. (The agent reschedules on saves from
        // either app and at midnight, so the baked content stays current.)
        let yesterday = DateKey.iso(DateKey.addDays(DateKey.today(), -1))
        let recap = StandupRecap.logged(on: yesterday, in: sprints)

        let content = UNMutableNotificationContent()
        content.title = StandupRecap.notificationTitle(recap)
        content.body = StandupRecap.notificationBody(recap)
        content.sound = .default

        var when = DateComponents()
        when.hour = hour
        when.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: true)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        center.removePendingNotificationRequests(withIdentifiers: [identifier])
        center.add(request)
    }
}
