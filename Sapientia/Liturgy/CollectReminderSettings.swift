import Foundation

/// Which days the collect reminder speaks on.
enum CollectReminderDays: String, CaseIterable {
  case everyDay
  /// Days governed by a saint or feast: any day with an `observance`.
  case saintsAndFeasts
  /// Only Feasts and Solemnities.
  case feastsOnly
}

/// Preferences for the collect reminder, in the same app-group suite as
/// `DailyOfficeSettings` and `PrayerSettings`, with the same
/// minutes-from-midnight storage and `object(forKey:)` reads.
///
/// It replaces the old 06:00 Feast day notice. Anyone who had that on keeps
/// an equivalent reminder with no action: until this reminder's own switch is
/// written, `isEnabled` reports the old one, and every other default already
/// matches the old cadence — every day, once, at 06:00.
enum CollectReminderSettings {
  private static let suite = UserDefaults(
    suiteName: "group.com.artempleton.sapientia"
  )!

  private enum Key {
    static let enabled = "sapientiaCollectReminderEnabled"
    static let whichDays = "sapientiaCollectReminderDays"
    static let times = "sapientiaCollectReminderTimes"
    static let eveningEnabled = "sapientiaCollectReminderEveningEnabled"
    static let eveningMinutes = "sapientiaCollectReminderEveningMinutes"
  }

  static let defaultMinutes = 6 * 60
  /// Before Compline's 21:00 default, so the two don't land together.
  static let defaultEveningMinutes = 20 * 60
  static let maximumTimes = 3

  static var isEnabled: Bool {
    get { (suite.object(forKey: Key.enabled) as? Bool) ?? PrayerSettings.feastNoticeEnabled }
    set { suite.set(newValue, forKey: Key.enabled) }
  }

  static var whichDays: CollectReminderDays {
    get {
      suite.string(forKey: Key.whichDays).flatMap(CollectReminderDays.init(rawValue:))
        ?? .everyDay
    }
    set { suite.set(newValue.rawValue, forKey: Key.whichDays) }
  }

  /// One to three distinct times of day, ascending.
  static var times: [Int] {
    get { normalised(suite.object(forKey: Key.times) as? [Int] ?? []) }
    set { suite.set(normalised(newValue), forKey: Key.times) }
  }

  static var eveningBeforeEnabled: Bool {
    get { (suite.object(forKey: Key.eveningEnabled) as? Bool) ?? false }
    set { suite.set(newValue, forKey: Key.eveningEnabled) }
  }

  static var eveningBeforeMinutes: Int {
    get { (suite.object(forKey: Key.eveningMinutes) as? Int) ?? defaultEveningMinutes }
    set { suite.set(newValue, forKey: Key.eveningMinutes) }
  }

  /// Keeps the first three distinct valid times, ascending; never empty.
  static func normalised(_ minutes: [Int]) -> [Int] {
    var seen = Set<Int>()
    let distinct = minutes.filter { (0..<24 * 60).contains($0) && seen.insert($0).inserted }
    let kept = Array(distinct.prefix(maximumTimes)).sorted()
    return kept.isEmpty ? [defaultMinutes] : kept
  }

  /// Test hook: clear every stored preference.
  static func reset() {
    for key in [Key.enabled, Key.whichDays, Key.times, Key.eveningEnabled, Key.eveningMinutes] {
      suite.removeObject(forKey: key)
    }
  }
}
