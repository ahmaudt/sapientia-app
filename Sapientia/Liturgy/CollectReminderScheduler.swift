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

/// Schedules the collect reminder: the day's governing observance and its
/// collect, at one to three times a day, plus an optional evening notice when
/// tomorrow keeps a saint or feast.
///
/// **A request budget, not a window.** Requests per day vary with the
/// settings (up to three morning notices and an evening one), so rather than
/// a fixed number of days this fills requests in time order until
/// `requestBudget` is spent. iOS keeps at most 64 pending local notifications
/// per app: the Little Hours hold 15, Matins/Evensong/Compline 27, and this
/// 14, leaving 8 for session timers. At the heaviest settings that is about
/// three days ahead; every foreground, session change and settings edit
/// refills it, and the nearest notices are never the ones dropped.
///
/// Identifiers are prefixed `collect-` so session cleanup (`TimersUtil`)
/// spares them. Each reschedule also clears the old `feast-` notices this
/// scheduler replaced.
struct CollectReminderScheduler {
  static let identifierPrefix = "collect-"
  static let legacyIdentifierPrefix = "feast-"
  static let requestBudget = 14
  /// How far ahead to look for qualifying days when the settings are sparse
  /// ("Feasts only") before giving up.
  static let lookaheadInDays = 120

  var center: UserNotificationCentering = SystemNotificationCenter()
  var calendar: Calendar = .current
  var liturgy: OrdinariateCalendar = OrdinariateCalendar()

  func reschedule(from startDate: Date = Date()) {
    center.pendingRequestIdentifiers { identifiers in
      let ours = identifiers.filter {
        $0.hasPrefix(Self.identifierPrefix) || $0.hasPrefix(Self.legacyIdentifierPrefix)
      }
      if !ours.isEmpty {
        center.removePendingRequests(withIdentifiers: ours)
      }

      guard CollectReminderSettings.isEnabled else { return }
      for request in requests(from: startDate) {
        center.add(request)
      }
    }
  }

  /// The requests to hold, earliest first, never more than `requestBudget`.
  func requests(from startDate: Date) -> [UNNotificationRequest] {
    let whichDays = CollectReminderSettings.whichDays
    let times = CollectReminderSettings.times
    let evening =
      CollectReminderSettings.eveningBeforeEnabled
      ? CollectReminderSettings.eveningBeforeMinutes : nil
    let firstDay = calendar.startOfDay(for: startDate)

    var scheduled: [UNNotificationRequest] = []
    var today = liturgy.day(for: firstDay)
    for offset in 0..<Self.lookaheadInDays {
      guard let day = calendar.date(byAdding: .day, value: offset, to: firstDay),
        let next = calendar.date(byAdding: .day, value: 1, to: day)
      else { break }
      let tomorrow = liturgy.day(for: next)

      var candidates: [(fire: Date, request: UNNotificationRequest)] = []
      if Self.qualifies(today, for: whichDays) {
        for minutes in times {
          let morning = notice(on: day, at: minutes, suffix: Self.clock(minutes)) {
            $0.title = "Today: \(today.observance?.phrase(capitalized: true) ?? today.dayName)"
            $0.body = today.collect.text
          }
          if let morning { candidates.append(morning) }
        }
      }
      // The evening before a saint or feast only: an ordinary weekday or
      // Sunday is not news the night before.
      if let evening, let observance = tomorrow.observance,
        Self.qualifies(tomorrow, for: whichDays),
        let eve = notice(
          on: day, at: evening, suffix: "eve",
          content: {
            $0.title = "Tomorrow is \(observance.phrase(capitalized: false))."
          })
      {
        candidates.append(eve)
      }

      for candidate in candidates.sorted(by: { $0.fire < $1.fire })
      where candidate.fire > startDate {
        scheduled.append(candidate.request)
        if scheduled.count == Self.requestBudget { return scheduled }
      }
      today = tomorrow
    }
    return scheduled
  }

  static func qualifies(_ day: LiturgicalDay, for whichDays: CollectReminderDays) -> Bool {
    switch whichDays {
    case .everyDay: return true
    case .saintsAndFeasts: return day.observance != nil
    case .feastsOnly:
      return day.observance.map { $0.rank == .feast || $0.rank == .solemnity } ?? false
    }
  }

  /// "0600" for 360 minutes.
  static func clock(_ minutes: Int) -> String {
    String(format: "%02d%02d", minutes / 60, minutes % 60)
  }

  /// `collect-2026-08-08-0600`, `collect-2026-08-07-eve`: unique per notice,
  /// and greppable.
  private func notice(
    on day: Date, at minutes: Int, suffix: String,
    content fill: (UNMutableNotificationContent) -> Void
  ) -> (fire: Date, request: UNNotificationRequest)? {
    var components = calendar.dateComponents([.year, .month, .day], from: day)
    components.hour = minutes / 60
    components.minute = minutes % 60
    guard let fire = calendar.date(from: components),
      let year = components.year, let month = components.month, let dayOfMonth = components.day
    else { return nil }

    let content = UNMutableNotificationContent()
    content.sound = .default
    fill(content)

    let identifier = String(
      format: "%@%04d-%02d-%02d-%@", Self.identifierPrefix, year, month, dayOfMonth, suffix)
    let request = UNNotificationRequest(
      identifier: identifier, content: content,
      trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false))
    return (fire, request)
  }
}
