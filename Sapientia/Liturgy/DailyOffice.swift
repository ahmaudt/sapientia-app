import Foundation

// The three offices Sapientia announces but does not carry.
//
// Matins, Evensong and Compline are prayed at the parish or from a physical
// copy of Divine Worship: Daily Office. None of their text ships here - this
// type exists so a notice can name them and a preference can time them.
//
// Deliberately separate from `LittleHour`. That enum feeds `KeptHoursStore`,
// the week grid's denominator and the office reader; these offices enter none
// of it, and adding cases there would have dragged all three in.

/// One of the three offices announced by notice alone.
///
/// Raw values match both the notification identifier suffix
/// (`daily-2026-09-04-evensong`) and the `UserDefaults` storage keys, so the
/// spelling is fixed in one place.
enum DailyOffice: String, CaseIterable, Hashable {
  case matins
  case evensong
  case compline

  /// "Matins", "Evensong", "Compline" - the notice title and the settings row.
  ///
  /// Written out rather than derived from `rawValue.capitalized`, for two
  /// reasons: `capitalized` is locale-driven, and the "Matins" spelling is a
  /// decision worth pinning where it can be read. One `t` - the app tracks
  /// Divine Worship: Daily Office, North American Edition, which spells it
  /// "Morning Prayer (Matins)". "Mattins" is the Commonwealth Edition.
  ///
  /// Deliberately not the Little Hours' two-part `displayTitle` form
  /// ("Midmorning - Terce"): those offices carry an English name and a Latin
  /// one and the screens show both, while these have a single name apiece.
  var displayName: String {
    switch self {
    case .matins: return "Matins"
    case .evensong: return "Evensong"
    case .compline: return "Compline"
    }
  }
}
