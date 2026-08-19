//
//  RecapNotifier.swift
//  SprintBuddyMenuBar
//
//  Owned by the agent: schedules the opt-in daily "standup recap" local
//  notification. Content (the last working day's updates, or a nudge naming
//  that day when nothing was logged) is baked in at schedule time, so it is
//  refreshed on the agent's launch / activation, after any save in either app
//  (Darwin signal), at midnight, on wake, and on a periodic drift check.
//  Reads its prefs from the shared defaults suite.
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

    /// The day the pending notification currently recaps ("none" when it
    /// recaps nothing), used to detect drift without rescheduling needlessly.
    private static var scheduledFor: String?

    /// Reschedules only when the day being recapped has moved on — safe to call
    /// on a timer, since it won't remove and re-add the pending request near
    /// its delivery time (which risks dropping that day's notification).
    static func refreshIfDayChanged(sprints: [SprintDTO]) {
        guard enabled else { return }
        guard target(for: sprints) != scheduledFor else { return }
        refresh(sprints: sprints)
    }

    private static func target(for sprints: [SprintDTO]) -> String {
        StandupRecap.lastWorkingDay(sprints, before: DateKey.iso(DateKey.today()))?.dateISO ?? "none"
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
        scheduledFor = nil
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    private static func schedule(sprints: [SprintDTO]) {
        // Recap the last working day — skipping weekends/holidays/leave that
        // weren't logged — so Monday's recap reaches back to Friday. (The agent
        // reschedules on saves from either app, at midnight, and on wake, so
        // the baked content stays current.)
        let recap = StandupRecap.lastWorkingDay(sprints, before: DateKey.iso(DateKey.today()))
        scheduledFor = recap?.dateISO ?? "none"

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
