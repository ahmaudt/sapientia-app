import Foundation
import UserNotifications

// Copy and decisions for the reminders screen, kept out of the view so they
// can be asserted directly.

struct PrayerReminderRow: Equatable {
  let hour: LittleHour
  /// "Midmorning — Terce".
  let title: String
  /// "The third hour."
  let caption: String
  /// "9:00".
  let timeLabel: String
  let isEnabled: Bool
}

struct PrayerNoticePreview: Equatable {
  let title: String
  let body: String
  let time: String
}

enum PrayerRemindersModel {

  static let settingsNotice = "Notices are turned off for Sapientia in iOS Settings."

  /// Whether to offer a route into iOS Settings.
  ///
  /// Only when the user has actually refused. `.notDetermined` means the
  /// system prompt still works, so sending them to Settings would be worse
  /// than asking; `.provisional` delivers quietly but does deliver.
  static func showsSettingsLink(for status: UNAuthorizationStatus) -> Bool {
    status == .denied
  }

  static func rows(dataset: LittleHoursDataset = .loadBundled()) -> [PrayerReminderRow] {
    LittleHour.allCases.map { hour in
      let office = dataset.office(hour)
      return PrayerReminderRow(
        hour: hour,
        title: office?.displayTitle ?? hour.rawValue.capitalized,
        caption: "\(office?.hourPhrase ?? "").",
        timeLabel: LittleHoursRowModel.timeLabel(LittleHoursSettings.minutes(for: hour)),
        isEnabled: LittleHoursSettings.isEnabled(hour))
    }
  }

  // MARK: - The Collect

  /// The collect reminder is capped by a request budget, not a number of
  /// days, so more reminders a day means fewer days scheduled ahead.
  static let collectHorizonCaption =
    "More reminders a day look fewer days ahead; opening Sapientia refills them."

  static func label(for days: CollectReminderDays) -> String {
    switch days {
    case .everyDay: return "Every day"
    case .saintsAndFeasts: return "Saints & feasts"
    case .feastsOnly: return "Feasts"
    }
  }

  /// The time a newly added reminder starts at: six hours after the last,
  /// stepping on past any already set. Nil once the maximum is reached.
  static func nextCollectTime(after times: [Int]) -> Int? {
    guard times.count < CollectReminderSettings.maximumTimes, let last = times.last else {
      return nil
    }
    var candidate = last
    for _ in 0..<4 {
      candidate = (candidate + 6 * 60) % (24 * 60)
      if !times.contains(candidate) { return candidate }
    }
    return nil
  }

  /// The card on screen 29 showing how iOS will render the notice. Built from
  /// the same dataset the scheduler uses, so the depiction cannot drift from
  /// the real thing.
  static func previewNotice(
    for hour: LittleHour = .sext,
    dataset: LittleHoursDataset = .loadBundled()
  ) -> PrayerNoticePreview {
    guard let office = dataset.office(hour) else {
      return PrayerNoticePreview(title: "", body: "", time: "")
    }
    return PrayerNoticePreview(
      title: office.displayTitle,
      body: "\(office.hourPhrase). \(office.psalmSummary).",
      time: LittleHoursRowModel.timeLabel(LittleHoursSettings.minutes(for: hour)))
  }
}

/// Applies an edit and reschedules.
///
/// Every mutation goes through here so none can forget the reschedule — an
/// edit that only writes the preference does nothing until the next launch.
struct RemindersEditor {
  var reschedule: () -> Void = { OfficeNotificationScheduler().reschedule() }
  var rescheduleCollect: () -> Void = { CollectReminderScheduler().reschedule() }

  func setTime(_ minutes: Int, for hour: LittleHour) {
    LittleHoursSettings.setMinutes(minutes, for: hour)
    reschedule()
  }

  func setEnabled(_ enabled: Bool, for hour: LittleHour) {
    LittleHoursSettings.setEnabled(enabled, for: hour)
    reschedule()
  }

  func setRemindsOnSundays(_ value: Bool) {
    LittleHoursSettings.remindsOnSundays = value
    reschedule()
  }

  func setRemindsDuringSession(_ value: Bool) {
    LittleHoursSettings.remindsDuringSession = value
    reschedule()
  }

  // MARK: - The Collect

  func setCollectEnabled(_ enabled: Bool) {
    CollectReminderSettings.isEnabled = enabled
    rescheduleCollect()
  }

  func setCollectDays(_ days: CollectReminderDays) {
    CollectReminderSettings.whichDays = days
    rescheduleCollect()
  }

  /// Refused (returning false, rescheduling nothing) past the maximum or for
  /// a time already set.
  @discardableResult
  func addCollectTime(_ minutes: Int) -> Bool {
    let times = CollectReminderSettings.times
    guard times.count < CollectReminderSettings.maximumTimes, !times.contains(minutes) else {
      return false
    }
    CollectReminderSettings.times = times + [minutes]
    rescheduleCollect()
    return true
  }

  /// Refused when it is the only time: a reminder that is on always has one.
  @discardableResult
  func removeCollectTime(at index: Int) -> Bool {
    var times = CollectReminderSettings.times
    guard times.count > 1, times.indices.contains(index) else { return false }
    times.remove(at: index)
    CollectReminderSettings.times = times
    rescheduleCollect()
    return true
  }

  func setCollectTime(_ minutes: Int, at index: Int) {
    var times = CollectReminderSettings.times
    guard times.indices.contains(index) else { return }
    times[index] = minutes
    CollectReminderSettings.times = times
    rescheduleCollect()
  }

  func setEveningBefore(_ enabled: Bool) {
    CollectReminderSettings.eveningBeforeEnabled = enabled
    rescheduleCollect()
  }

  func setEveningMinutes(_ minutes: Int) {
    CollectReminderSettings.eveningBeforeMinutes = minutes
    rescheduleCollect()
  }
}
