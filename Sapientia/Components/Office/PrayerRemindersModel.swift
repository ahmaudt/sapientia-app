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
}
