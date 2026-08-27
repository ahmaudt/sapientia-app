import Foundation
import UserNotifications

/// Thin seam over UNUserNotificationCenter so notification behavior is
/// unit-testable (the real center cannot be constructed in tests).
protocol UserNotificationCentering {
  func pendingRequestIdentifiers(completion: @escaping ([String]) -> Void)
  func removePendingRequests(withIdentifiers identifiers: [String])
  func add(_ request: UNNotificationRequest)
  func requestAuthorization(completion: @escaping (Bool) -> Void)
  /// Current permission, distinct from requesting it: iOS shows the prompt
  /// only once per install, so a screen that offers to enable notices has to
  /// be able to tell "not asked yet" from "already refused".
  func authorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void)
}

extension UserNotificationCentering {
  /// Default so existing conformances — including test doubles that predate
  /// this requirement — need no change.
  func authorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
    completion(.authorized)
  }
}

struct SystemNotificationCenter: UserNotificationCentering {
  func pendingRequestIdentifiers(completion: @escaping ([String]) -> Void) {
    UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
      completion(requests.map(\.identifier))
    }
  }

  func removePendingRequests(withIdentifiers identifiers: [String]) {
    UNUserNotificationCenter.current()
      .removePendingNotificationRequests(withIdentifiers: identifiers)
  }

  func add(_ request: UNNotificationRequest) {
    UNUserNotificationCenter.current().add(request)
  }

  func requestAuthorization(completion: @escaping (Bool) -> Void) {
    UNUserNotificationCenter.current().requestAuthorization(
      options: [.alert, .sound, .badge]
    ) { granted, _ in
      completion(granted)
    }
  }

  func authorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
    UNUserNotificationCenter.current().getNotificationSettings { settings in
      completion(settings.authorizationStatus)
    }
  }
}

/// Schedules the 6:00 feast-day notices: a rolling 14-day window of local
/// notifications carrying the day's name and its feast or commemoration.
/// Identifiers are prefixed `feast-` so session-timer cleanup
/// (`TimersUtil`) never touches them. Rescheduled on app foreground and
/// after session start/stop; if the app is unopened for 14+ days the
/// window runs dry until next launch (documented limitation).
struct FeastNotificationScheduler {
  static let identifierPrefix = "feast-"
  static let windowInDays = 14

  var center: UserNotificationCentering = SystemNotificationCenter()
  var calendar: OrdinariateCalendar = OrdinariateCalendar()

  func reschedule(from startDate: Date = Date()) {
    center.pendingRequestIdentifiers { identifiers in
      let feastIdentifiers = identifiers.filter {
        $0.hasPrefix(Self.identifierPrefix)
      }
      if !feastIdentifiers.isEmpty {
        center.removePendingRequests(withIdentifiers: feastIdentifiers)
      }

      guard PrayerSettings.feastNoticeEnabled else { return }

      let gregorian = Calendar(identifier: .gregorian)
      for offset in 0..<Self.windowInDays {
        guard
          let day = gregorian.date(byAdding: .day, value: offset, to: startDate)
        else { continue }
        center.add(request(for: day, gregorian: gregorian))
      }
    }
  }

  private func request(
    for date: Date, gregorian: Calendar
  ) -> UNNotificationRequest {
    let liturgicalDay = calendar.day(for: date)

    let content = UNMutableNotificationContent()
    content.title = liturgicalDay.dayName
    content.body =
      liturgicalDay.commemorationText
      ?? "The Collect of \(liturgicalDay.collect.title) awaits."
    content.sound = .default

    var components = gregorian.dateComponents([.year, .month, .day], from: date)
    components.hour = 6
    components.minute = 0

    let identifier = String(
      format: "%@%04d-%02d-%02d",
      Self.identifierPrefix,
      components.year ?? 0, components.month ?? 0, components.day ?? 0)

    return UNNotificationRequest(
      identifier: identifier,
      content: content,
      trigger: UNCalendarNotificationTrigger(
        dateMatching: components, repeats: false)
    )
  }
}
