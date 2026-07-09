//
//  RecapNotifier.swift
//  SprintBuddy
//
//  Schedules the opt-in daily "standup recap" local notification. The content
//  (most recent logged day) is baked in at schedule time and refreshed on app
//  launch, data changes, and settings changes — the app is always-on in the
//  menu bar, so the pending notification stays current. Reads its prefs from
//  the same UserDefaults keys AppState writes.
//

import Foundation
import UserNotifications

enum RecapNotifier {
    private static let identifier = "daily-recap"
    private static var center: UNUserNotificationCenter { .current() }

    private static var enabled: Bool { UserDefaults.standard.bool(forKey: "recapEnabled") }
    private static var hour: Int { (UserDefaults.standard.object(forKey: "recapHour") as? Int) ?? 10 }
    private static var minute: Int { (UserDefaults.standard.object(forKey: "recapMinute") as? Int) ?? 0 }

    /// Prompts for notification permission. Returns whether it's now allowed.
    @discardableResult
    static func requestAuthorization() async -> Bool {
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        return granted
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
        let recap = StandupRecap.mostRecentLogged(sprints, onOrBefore: DateKey.iso(DateKey.today()))

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
