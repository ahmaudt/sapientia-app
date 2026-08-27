import Foundation

/// Which hours have been prayed, and when.
///
/// A kept hour is one small dated fact with no relations and nothing to query,
/// so it lives in the app-group `UserDefaults` beside `PrayerSettings` rather
/// than becoming a third SwiftData model needing a schema migration.
///
/// Entries are keyed `"yyyy-MM-dd|terce"`. The date component is always the
/// day the office was *opened for*, supplied by the caller — never `Date()`
/// read at write time, which would file an Amen tapped at 00:02 against the
/// wrong day.
struct KeptHoursStore {
  private let suite: UserDefaults
  private let calendar: Calendar

  /// Entries older than this are dropped on the next write, so the dictionary
  /// cannot grow without bound.
  static let retentionDays = 90

  init(
    suite: UserDefaults = UserDefaults(suiteName: "group.com.artempleton.sapientia")!,
    calendar: Calendar = .current
  ) {
    self.suite = suite
    self.calendar = calendar
  }

  private static let storageKey = "sapientiaKeptHours"

  private var dayFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM-dd"
    return formatter
  }

  /// "9:04" — the label screen 25 shows beside a kept hour.
  ///
  /// Deliberately 24-hour rather than locale-driven. The design writes the
  /// hours as "9:00", "12:00" and "15:00", and shows a kept Terce as
  /// "Prayed 9:04"; a localized template yields "9:04 AM" on a US device,
  /// which would sit inconsistently beside None's "15:00" in the very same
  /// list. The canonical hours read as clock positions here, not wall time.
  private var timeLabelFormatter: DateFormatter {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "H:mm"
    return formatter
  }

  func dayKey(for date: Date) -> String {
    dayFormatter.string(from: date)
  }

  private func key(_ hour: LittleHour, on date: Date) -> String {
    "\(dayKey(for: date))|\(hour.rawValue)"
  }

  private var entries: [String: String] {
    suite.dictionary(forKey: Self.storageKey) as? [String: String] ?? [:]
  }

  // MARK: - Reading

  func wasKept(_ hour: LittleHour, on date: Date) -> Bool {
    entries[key(hour, on: date)] != nil
  }

  func keptAt(_ hour: LittleHour, on date: Date) -> Date? {
    guard let stamp = entries[key(hour, on: date)] else { return nil }
    return ISO8601DateFormatter().date(from: stamp)
  }

  func keptTimeLabel(_ hour: LittleHour, on date: Date) -> String? {
    guard let kept = keptAt(hour, on: date) else { return nil }
    return timeLabelFormatter.string(from: kept)
  }

  var entryCount: Int {
    entries.count
  }

  // MARK: - Writing

  /// - Parameters:
  ///   - day: the day the office was opened for.
  ///   - time: when the Amen was actually tapped, which may be a later day.
  func record(_ hour: LittleHour, on day: Date, at time: Date) {
    var updated = pruned(entries, relativeTo: day)
    updated[key(hour, on: day)] = ISO8601DateFormatter().string(from: time)
    suite.set(updated, forKey: Self.storageKey)
  }

  /// Drop anything older than the retention window. Keyed off the day being
  /// written rather than `Date()` so behavior is deterministic under test.
  private func pruned(_ entries: [String: String], relativeTo day: Date) -> [String: String] {
    guard
      let cutoff = calendar.date(byAdding: .day, value: -Self.retentionDays, to: day)
    else { return entries }
    let cutoffKey = dayKey(for: cutoff)
    // Keys begin with an ISO day, so a lexical comparison is a date
    // comparison — no parsing per entry.
    return entries.filter { element in
      guard let dayPart = element.key.split(separator: "|").first else { return false }
      return String(dayPart) > cutoffKey
    }
  }

  /// Test hook: clear every recorded hour.
  func reset() {
    suite.removeObject(forKey: Self.storageKey)
  }
}
