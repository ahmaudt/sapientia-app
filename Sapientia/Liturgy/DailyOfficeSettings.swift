import Foundation

/// Reminder preferences for Matins, Evensong and Compline, in the same
/// app-group suite as `LittleHoursSettings` and `PrayerSettings`.
///
/// Structurally a twin of `LittleHoursSettings` - same minutes-from-midnight
/// storage, same `object(forKey:)` reads - with two deliberate differences:
///
/// - **Sundays remind by default.** The Little Hours go quiet on Sunday
///   because the day belongs to the parish; these three ring *because* it
///   does. That inversion is the reason the two sets need separate switches
///   rather than sharing one.
/// - **There is no `remindsDuringSession` twin.** That toggle is stored and
///   displayed but read by no scheduler; the promise it describes is kept by
///   `TimersUtil.preservedPrefixes` sparing this file's identifier prefix.
///
/// No derived counts either (`enabledHourCount` and friends) - those exist to
/// feed the week grid, which these offices never enter.
enum DailyOfficeSettings {
  private static let suite = UserDefaults(
    suiteName: "group.com.artempleton.sapientia"
  )!

  private enum Key {
    static func enabled(_ office: DailyOffice) -> String {
      "sapientiaDailyOffice_\(office.rawValue)_enabled"
    }
    static func minutes(_ office: DailyOffice) -> String {
      "sapientiaDailyOffice_\(office.rawValue)_minutes"
    }
    static let remindsOnSundays = "sapientiaDailyOfficeRemindOnSundays"
  }

  /// Matins 8:45 and Evensong 17:30 are the published daily times of the
  /// Ordinariate of the Chair of Saint Peter community at prayer.covert.org -
  /// the same source `scripts/liturgy/` generates the Little Hours from.
  /// Compline has no canonical clock hour in any source consulted (uniformly
  /// "before going to bed"), so 21:00 is a stated convention, and the default
  /// most likely to be changed.
  static func defaultMinutes(for office: DailyOffice) -> Int {
    switch office {
    case .matins: return 8 * 60 + 45
    case .evensong: return 17 * 60 + 30
    case .compline: return 21 * 60
    }
  }

  // MARK: - Per-office

  /// Reading through `object(forKey:)` rather than `integer(forKey:)` is not
  /// fussiness: the latter returns 0 for an absent key, which is
  /// indistinguishable from a user who set the office to midnight.
  static func minutes(for office: DailyOffice) -> Int {
    guard let stored = suite.object(forKey: Key.minutes(office)) as? Int else {
      return defaultMinutes(for: office)
    }
    return stored
  }

  static func setMinutes(_ minutes: Int, for office: DailyOffice) {
    suite.set(minutes, forKey: Key.minutes(office))
  }

  /// Same reasoning as `minutes(for:)`: `bool(forKey:)` reports false for an
  /// absent key, but every office reminds until the user says otherwise.
  static func isEnabled(_ office: DailyOffice) -> Bool {
    guard let stored = suite.object(forKey: Key.enabled(office)) as? Bool else {
      return true
    }
    return stored
  }

  static func setEnabled(_ enabled: Bool, for office: DailyOffice) {
    suite.set(enabled, forKey: Key.enabled(office))
  }

  // MARK: - Conduct

  /// Defaults **true**, the inverse of `LittleHoursSettings.remindsOnSundays`.
  /// Sunday is the day Matins and Evensong most belong to the parish, which
  /// makes it the day the call matters most.
  static var remindsOnSundays: Bool {
    get {
      (suite.object(forKey: Key.remindsOnSundays) as? Bool) ?? true
    }
    set { suite.set(newValue, forKey: Key.remindsOnSundays) }
  }

  /// Test hook: clear every stored preference.
  static func reset() {
    for office in DailyOffice.allCases {
      suite.removeObject(forKey: Key.enabled(office))
      suite.removeObject(forKey: Key.minutes(office))
    }
    suite.removeObject(forKey: Key.remindsOnSundays)
  }
}
