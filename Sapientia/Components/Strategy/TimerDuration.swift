import Foundation

/// The duration screen's arithmetic and copy, as pure functions.
///
/// Kept out of `TimerDurationView` so the boundaries — the 15-minute floor,
/// the 23:59 ceiling, the h:mm rollover — are unit-testable without standing
/// up a view. Mirrors the way `ShieldContent` holds the shield's copy.
enum TimerDuration {

  // MARK: - Bounds

  static let minimumMinutes = 15
  /// 23h 59m. A full 24h would read as "24:00", which invites the question of
  /// whether it means today or tomorrow.
  static let maximumMinutes = 1439
  static let stepMinutes = 5

  /// The tag row from design 16: 30m · 1h · 1h 30m · 3h.
  static let presetMinutes = [30, 60, 90, 180]

  static func clamped(_ minutes: Int) -> Int {
    min(max(minutes, minimumMinutes), maximumMinutes)
  }

  static func stepped(_ minutes: Int, by delta: Int) -> Int {
    clamped(minutes + delta)
  }

  // MARK: - Display

  /// The 68pt numeral: hours, colon, zero-padded minutes.
  static func clockText(_ minutes: Int) -> String {
    let total = clamped(minutes)
    return String(format: "%d:%02d", total / 60, total % 60)
  }

  /// The preset tags: whole units only, zero components dropped.
  static func compactText(_ minutes: Int) -> String {
    let total = clamped(minutes)
    let hours = total / 60
    let remainder = total % 60

    switch (hours, remainder) {
    case (0, let m): return "\(m)m"
    case (let h, 0): return "\(h)h"
    case (let h, let m): return "\(h)h \(m)m"
    }
  }

  // MARK: - Lift time

  static func liftsAt(_ minutes: Int, from start: Date) -> Date {
    start.addingTimeInterval(TimeInterval(clamped(minutes) * 60))
  }

  /// The line above the action button.
  ///
  /// The mockup's wording — "Nothing ends it early but an emergency unblock"
  /// — assumes the stop button is hidden. It is only offered when that is
  /// actually the case; otherwise the sentence would promise a strictness the
  /// session does not have.
  static func consequence(endTime: String, canStopEarly: Bool) -> String {
    canStopEarly
      ? "It lifts at \(endTime). You can stop it early with the Stop button."
      : "It lifts at \(endTime). Nothing ends it early but an emergency unblock."
  }
}
