import Foundation

/// Which prayer the block shield presents.
enum BlockScreenPrayer: String {
  case benedict
  case collect
}

/// Liturgical calendar in use. Roman is visible in Settings but not yet
/// available — only `.ordinariate` ships in this release.
enum LiturgicalCalendarChoice: String {
  case ordinariate
  case roman
}

/// App-group-backed prayer preferences, readable by the main app and the
/// SapientiaShieldConfig extension alike.
enum PrayerSettings {
  private static let suite = UserDefaults(
    suiteName: "group.dev.ambitionsoftware.sapientia"
  )!

  private enum Key: String {
    case blockScreenPrayer = "sapientiaBlockScreenPrayer"
    case calendarChoice = "sapientiaCalendarChoice"
    case feastNoticeEnabled = "sapientiaFeastNoticeEnabled"
  }

  /// The Prayer of St. Benedict — the app's foundational prayer. A
  /// guaranteed constant so the shield can never come up empty.
  static let benedictPrayerText =
    "O GRACIOUS and holy Father, give us Wisdom to perceive thee, diligence to seek thee, patience to wait for thee, eyes to behold thee, a heart to meditate upon thee, and a life to proclaim thee; through the power of the Spirit of Jesus Christ our Lord. Amen."

  /// Shortened form, pre-defined fallback should the full prayer truncate
  /// on small shield layouts (see plan, Task 3).
  static let benedictPrayerShortText =
    "Give us wisdom to perceive thee, diligence to seek thee, patience to wait for thee; through Jesus Christ our Lord. Amen."

  static var blockScreenPrayer: BlockScreenPrayer {
    get {
      suite.string(forKey: Key.blockScreenPrayer.rawValue)
        .flatMap(BlockScreenPrayer.init(rawValue:)) ?? .benedict
    }
    set { suite.set(newValue.rawValue, forKey: Key.blockScreenPrayer.rawValue) }
  }

  static var calendarChoice: LiturgicalCalendarChoice {
    get {
      suite.string(forKey: Key.calendarChoice.rawValue)
        .flatMap(LiturgicalCalendarChoice.init(rawValue:)) ?? .ordinariate
    }
    set { suite.set(newValue.rawValue, forKey: Key.calendarChoice.rawValue) }
  }

  static var feastNoticeEnabled: Bool {
    get { suite.bool(forKey: Key.feastNoticeEnabled.rawValue) }
    set { suite.set(newValue, forKey: Key.feastNoticeEnabled.rawValue) }
  }

  /// Test hook: clear all stored prayer preferences.
  static func reset() {
    suite.removeObject(forKey: Key.blockScreenPrayer.rawValue)
    suite.removeObject(forKey: Key.calendarChoice.rawValue)
    suite.removeObject(forKey: Key.feastNoticeEnabled.rawValue)
  }
}
