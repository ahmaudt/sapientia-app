import Foundation

/// Reminder preferences for the Little Hours, in the same app-group suite as
/// `PrayerSettings`. Kept separate so that file stays about the block screen
/// rather than becoming a grab-bag.
///
/// Times are stored as minutes from midnight rather than `Date`s: a `Date`
/// pins an instant, which is the wrong shape for "every day at noon" and
/// drifts across timezone changes. `UNCalendarNotificationTrigger` wants hour
/// and minute components anyway, and re-resolves them locally each day.
enum LittleHoursSettings {
  private static let suite = UserDefaults(
    suiteName: "group.com.artempleton.sapientia"
  )!

  private enum Key {
    static func enabled(_ hour: LittleHour) -> String {
      "sapientiaLittleHour_\(hour.rawValue)_enabled"
    }
    static func minutes(_ hour: LittleHour) -> String {
      "sapientiaLittleHour_\(hour.rawValue)_minutes"
    }
    static let remindsOnSundays = "sapientiaLittleHoursRemindOnSundays"
    static let remindsDuringSession = "sapientiaLittleHoursRemindDuringSession"
  }

  /// The traditional hours: the third, sixth and ninth of the day.
  static func defaultMinutes(for hour: LittleHour) -> Int {
    switch hour {
    case .terce: return 9 * 60
    case .sext: return 12 * 60
    case .nones: return 15 * 60
    }
  }

  // MARK: - Per-hour

  /// Reading through `object(forKey:)` rather than `integer(forKey:)` is not
  /// fussiness: the latter returns 0 for an absent key, which is
  /// indistinguishable from a user who set the hour to midnight.
  static func minutes(for hour: LittleHour) -> Int {
    guard let stored = suite.object(forKey: Key.minutes(hour)) as? Int else {
      return defaultMinutes(for: hour)
    }
    return stored
  }

  static func setMinutes(_ minutes: Int, for hour: LittleHour) {
    suite.set(minutes, forKey: Key.minutes(hour))
  }

  /// Same reasoning as `minutes(for:)`: `bool(forKey:)` reports false for an
  /// absent key, but every hour reminds until the user says otherwise.
  static func isEnabled(_ hour: LittleHour) -> Bool {
    guard let stored = suite.object(forKey: Key.enabled(hour)) as? Bool else {
      return true
    }
    return stored
  }

  static func setEnabled(_ enabled: Bool, for hour: LittleHour) {
    suite.set(enabled, forKey: Key.enabled(hour))
  }

  // MARK: - Conduct

  /// Screen 29: Sundays are quiet — Matins and Evensong belong to the parish.
  static var remindsOnSundays: Bool {
    get {
      (suite.object(forKey: Key.remindsOnSundays) as? Bool) ?? false
    }
    set { suite.set(newValue, forKey: Key.remindsOnSundays) }
  }

  /// Screen 29: the notice still comes during a held session — the office is
  /// never blocked.
  static var remindsDuringSession: Bool {
    get {
      (suite.object(forKey: Key.remindsDuringSession) as? Bool) ?? true
    }
    set { suite.set(newValue, forKey: Key.remindsDuringSession) }
  }

  // MARK: - Derived counts

  /// Days in a week that can carry a notice. The week grid's denominator is
  /// this times `enabledHourCount`.
  static var enabledWeekdayCount: Int {
    remindsOnSundays ? 7 : 6
  }

  /// How many of the three hours are switched on. The grid must multiply by
  /// this, not by a constant 3 — otherwise switching an hour off leaves the
  /// user staring at a target they can no longer reach.
  static var enabledHourCount: Int {
    LittleHour.allCases.filter(isEnabled).count
  }

  /// Enabled hours in clock order. "Current hour" is the earliest overdue one,
  /// so callers need them ordered by time rather than by declaration — the
  /// user may have moved Terce past Sext.
  static var enabledHours: [LittleHour] {
    LittleHour.allCases
      .filter(isEnabled)
      .sorted { left, right in
        let leftMinutes = minutes(for: left)
        let rightMinutes = minutes(for: right)
        if leftMinutes == rightMinutes {
          // Stable tiebreak, so equal times never reorder between reads.
          return canonicalOrder(left) < canonicalOrder(right)
        }
        return leftMinutes < rightMinutes
      }
  }

  private static func canonicalOrder(_ hour: LittleHour) -> Int {
    LittleHour.allCases.firstIndex(of: hour) ?? 0
  }

  /// Test hook: clear every stored preference.
  static func reset() {
    for hour in LittleHour.allCases {
      suite.removeObject(forKey: Key.enabled(hour))
      suite.removeObject(forKey: Key.minutes(hour))
    }
    suite.removeObject(forKey: Key.remindsOnSundays)
    suite.removeObject(forKey: Key.remindsDuringSession)
  }
}
