import Foundation
import UserNotifications

/// Schedules the notice that names each Little Hour as it comes.
///
/// Structure follows `FeastNotificationScheduler`: the same
/// `UserNotificationCentering` seam (so this is testable without the real
/// centre), a rolling window rebuilt on every foreground, and an identifier
/// prefix that `TimersUtil` preserves through session cleanup.
///
/// The window is deliberately shorter than the feast scheduler's. iOS keeps at
/// most **64** pending local notifications per app and silently discards the
/// rest; three hours a day for fourteen days would be 42, which together with
/// the 14 feast notices leaves almost nothing for session timers. Ten days
/// caps this at 30. Since the app reschedules whenever it comes to the
/// foreground, the shorter horizon costs nothing in practice — with the same
/// caveat the feast scheduler carries: an app left unopened past the window
/// runs dry until next launch.
struct OfficeNotificationScheduler {
  static let identifierPrefix = "office-"
  static let windowInDays = 10
  /// iOS's documented ceiling on pending local notifications per app.
  static let systemPendingLimit = 64

  var center: UserNotificationCentering = SystemNotificationCenter()
  var calendar: Calendar = .current
  var store: KeptHoursStore = KeptHoursStore()
  var dataset: LittleHoursDataset = .loadBundled()

  func reschedule(from startDate: Date = Date()) {
    center.pendingRequestIdentifiers { identifiers in
      let ours = identifiers.filter { $0.hasPrefix(Self.identifierPrefix) }
      if !ours.isEmpty {
        center.removePendingRequests(withIdentifiers: ours)
      }

      for offset in 0..<Self.windowInDays {
        guard let day = calendar.date(byAdding: .day, value: offset, to: startDate) else {
          continue
        }
        scheduleDay(day)
      }
    }
  }

  private func scheduleDay(_ day: Date) {
    // A quiet Sunday gets nothing at all — Matins and Evensong belong to the
    // parish, per screen 29.
    let isSunday = calendar.component(.weekday, from: day) == 1
    if isSunday && !LittleHoursSettings.remindsOnSundays { return }

    for hour in LittleHour.allCases {
      guard LittleHoursSettings.isEnabled(hour) else { continue }
      // "dismissed by praying it or by the day ending" — an hour already kept
      // must not be announced again.
      guard !store.wasKept(hour, on: day) else { continue }
      guard let request = request(for: hour, on: day) else { continue }
      center.add(request)
    }
  }

  private func request(for hour: LittleHour, on day: Date) -> UNNotificationRequest? {
    guard let office = dataset.office(hour) else { return nil }

    let content = UNMutableNotificationContent()
    content.title = office.displayTitle
    content.body = "\(office.hourPhrase). \(office.psalmSummary)."
    content.sound = .default

    let minutes = LittleHoursSettings.minutes(for: hour)
    var components = calendar.dateComponents([.year, .month, .day], from: day)
    components.hour = minutes / 60
    components.minute = minutes % 60

    return UNNotificationRequest(
      identifier: identifier(for: hour, on: day),
      content: content,
      trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    )
  }

  /// `office-YYYY-MM-DD-terce` — unique per hour per day, and greppable.
  func identifier(for hour: LittleHour, on day: Date) -> String {
    "\(Self.identifierPrefix)\(store.dayKey(for: day))-\(hour.rawValue)"
  }
}
