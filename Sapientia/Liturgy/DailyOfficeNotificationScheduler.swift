import Foundation
import UserNotifications

/// Schedules the notices for **Matins, Evensong and Compline** - the three
/// offices the app announces but does not carry.
///
/// Not to be confused with `OfficeNotificationScheduler`, which covers the
/// **Little Hours** (Terce, Sext and None). The names are close; the two
/// differ in what they schedule and in two behaviours:
///
/// - **No kept-hours skip.** A Little Hour already prayed in the app gets no
///   notice that day. Nothing can mark these three prayed - there is no
///   reader - so every enabled office is announced every day.
/// - **Sundays remind by default**, the inverse of the Little Hours. Sunday
///   is the day these offices most belong to the parish, which makes it the
///   day the call matters most.
///
/// The body names the day rather than repeating fixed copy, which is why this
/// is a rolling window of one-shot triggers rather than three repeating ones:
/// a repeating `UNCalendarNotificationTrigger` would cost a single pending
/// slot per office, but can only carry text that never changes.
///
/// **The window is 9 days.** iOS keeps at most 64 pending local notifications
/// per app and silently discards the rest. Nine days here is 27, the Little
/// Hours' five days is 15, and collect reminders hold at most 14 - 56 in all,
/// leaving 8 for session timers. The app reschedules whenever it comes to the
/// foreground, and any notification tap brings it there, so the horizon only
/// lapses for someone who ignores every notice and never opens the app.
struct DailyOfficeNotificationScheduler {
  static let identifierPrefix = "daily-"
  static let windowInDays = 9

  var center: UserNotificationCentering = SystemNotificationCenter()
  var calendar: Calendar = .current
  var liturgy: OrdinariateCalendar = OrdinariateCalendar()

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
    let isSunday = calendar.component(.weekday, from: day) == 1
    if isSunday && !DailyOfficeSettings.remindsOnSundays { return }

    for office in DailyOffice.allCases {
      guard DailyOfficeSettings.isEnabled(office) else { continue }
      guard let request = request(for: office, on: day) else { continue }
      center.add(request)
    }
  }

  private func request(for office: DailyOffice, on day: Date) -> UNNotificationRequest? {
    var components = calendar.dateComponents([.year, .month, .day], from: day)
    guard let year = components.year,
      let month = components.month,
      let dayOfMonth = components.day
    else { return nil }

    let content = UNMutableNotificationContent()
    content.title = office.displayName
    // The day's own designation - "Trinity XXIV", "Christmas Day". Not
    // `commemorationText`, which is frequently nil and names a saint rather
    // than the day.
    content.body = "\(liturgy.day(for: day).dayName)."
    content.sound = .default

    let minutes = DailyOfficeSettings.minutes(for: office)
    components.hour = minutes / 60
    components.minute = minutes % 60

    return UNNotificationRequest(
      identifier: identifier(for: office, year: year, month: month, day: dayOfMonth),
      content: content,
      trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
    )
  }

  /// `daily-2026-09-04-evensong` - unique per office per day, and greppable.
  ///
  /// Built from date components rather than a `DateFormatter`, matching
  /// `CollectReminderScheduler`, so no formatter is allocated per request.
  func identifier(for office: DailyOffice, year: Int, month: Int, day: Int) -> String {
    String(
      format: "%@%04d-%02d-%02d-%@",
      Self.identifierPrefix, year, month, day, office.rawValue)
  }
}
