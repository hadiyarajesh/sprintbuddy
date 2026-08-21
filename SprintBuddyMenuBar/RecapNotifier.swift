//
//  RecapNotifier.swift
//  SprintBuddyMenuBar
//
//  Owned by the agent: delivers the opt-in daily "standup recap" notification.
//
//  Content is built at DELIVERY time, not schedule time. An earlier version
//  baked the text into a repeating UNCalendarNotificationTrigger, which meant
//  any missed refresh delivered an older day's recap (e.g. an "Aug 17" recap
//  arriving on Aug 21). Instead the resident agent arms a timer for the next
//  recap time and posts an untriggered request when it fires, reading the store
//  right then — so the text can't be stale by construction.
//
//  Prefs come from the shared defaults suite; `PrefKey.recapLastDelivered`
//  guards against double-notifying when the timer is re-armed after sleep or a
//  relaunch.
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

    private static var lastDelivered: String? {
        get { AppGroup.defaults.string(forKey: PrefKey.recapLastDelivered) }
        set { AppGroup.defaults.set(newValue, forKey: PrefKey.recapLastDelivered) }
    }

    /// Supplies current sprint data, set once by the app delegate. Called at
    /// delivery time so the recap always reflects the latest store contents.
    static var dataSource: (() -> [SprintDTO])?

    private static var timer: Timer?

    /// Prompts for notification permission. Returns whether it's now allowed.
    @discardableResult
    static func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    /// Arms (or re-arms) the recap timer. Idempotent and cheap — call on launch,
    /// on wake, when the day changes, and after any pref change.
    static func refresh() {
        timer?.invalidate()
        timer = nil
        guard enabled else { return }
        center.getNotificationSettings { settings in
            let allowed = settings.authorizationStatus == .authorized
                || settings.authorizationStatus == .provisional
            DispatchQueue.main.async {
                if allowed { arm() } else { cancel() }
            }
        }
    }

    static func cancel() {
        timer?.invalidate()
        timer = nil
        center.removePendingNotificationRequests(withIdentifiers: [identifier])
    }

    // MARK: - Timing

    private static func arm() {
        let now = Date()
        let calendar = Calendar.current
        guard let todayFire = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: now) else { return }
        let todayISO = DateKey.iso(DateKey.today())

        if now >= todayFire {
            if lastDelivered == nil {
                // First time set up, after today's time — don't back-fill a
                // recap the moment the feature is switched on.
                lastDelivered = todayISO
            } else if lastDelivered != todayISO {
                // Missed today's slot (asleep, or the agent wasn't running).
                deliver()
            }
        }

        let next = now < todayFire
            ? todayFire
            : (calendar.date(byAdding: .day, value: 1, to: todayFire) ?? todayFire.addingTimeInterval(86_400))
        let scheduled = Timer(fire: next, interval: 0, repeats: false) { _ in
            deliver()
            arm()   // chain to the following day
        }
        RunLoop.main.add(scheduled, forMode: .common)
        timer = scheduled
    }

    /// Builds and posts the notification from current data. Reuses one
    /// identifier so only the latest recap sits in Notification Center.
    private static func deliver() {
        let todayISO = DateKey.iso(DateKey.today())
        guard enabled, lastDelivered != todayISO else { return }
        let recap = StandupRecap.lastWorkingDay(dataSource?() ?? [], before: todayISO)

        let content = UNMutableNotificationContent()
        content.title = StandupRecap.notificationTitle(recap)
        content.body = StandupRecap.notificationBody(recap)
        content.sound = .default

        lastDelivered = todayISO
        NSLog("[SprintBuddy] Delivering recap: \(content.title)")
        center.add(UNNotificationRequest(identifier: identifier, content: content, trigger: nil))
    }
}
