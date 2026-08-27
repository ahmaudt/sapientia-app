import Foundation

// The week grid on screen 25: seven columns of three cells, and the caption
// beneath it. Pure and synchronous, mirroring `ObservedDaysAggregator`.

/// One cell of the grid.
enum KeptHourCell: Equatable {
  case kept
  case notKept
  /// The hour is switched off, or the day is a quiet Sunday — nothing is owed,
  /// so the cell renders inert rather than as a failure.
  case notRequired
}

struct KeptHoursDay: Equatable {
  let date: Date
  /// Three cells in `LittleHour.allCases` order — Terce, Sext, None.
  let cells: [KeptHourCell]
}

struct KeptHoursWeek: Equatable {
  /// Sunday through Saturday, matching the grid's column order.
  let days: [KeptHoursDay]
  /// Hours the user's own rule asks for this week.
  let denominator: Int
  /// Required hours actually kept. Never exceeds `denominator`.
  let keptCount: Int

  /// "Twelve of eighteen hours kept so far this week." — spelled out, as the
  /// design writes it.
  var caption: String {
    "\(Self.spelled(keptCount, capitalized: true)) of \(Self.spelled(denominator)) hours kept so far this week."
  }

  private static func spelled(_ value: Int, capitalized: Bool = false) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    formatter.locale = Locale(identifier: "en_US")
    let words = formatter.string(from: NSNumber(value: value)) ?? String(value)
    guard capitalized, let first = words.first else { return words }
    return first.uppercased() + words.dropFirst()
  }
}

enum KeptHoursAggregator {

  /// Build the week containing `date`.
  ///
  /// The denominator is `enabledWeekdayCount × enabledHourCount` — never a
  /// fixed 3. With an hour switched off, a hardcoded multiplier would show a
  /// target the user cannot reach.
  static func aggregate(
    weekOf date: Date,
    store: KeptHoursStore,
    calendar: Calendar = .current,
    remindsOnSundays: Bool? = nil,
    isEnabled: ((LittleHour) -> Bool)? = nil
  ) -> KeptHoursWeek {
    let sundaysCount = remindsOnSundays ?? LittleHoursSettings.remindsOnSundays
    let enabled = isEnabled ?? { LittleHoursSettings.isEnabled($0) }

    let start = startOfWeek(for: date, calendar: calendar)
    var days: [KeptHoursDay] = []
    var keptCount = 0

    for offset in 0..<7 {
      guard let day = calendar.date(byAdding: .day, value: offset, to: start) else { continue }
      let isSunday = calendar.component(.weekday, from: day) == 1
      let dayIsQuiet = isSunday && !sundaysCount

      var cells: [KeptHourCell] = []
      for hour in LittleHour.allCases {
        let required = enabled(hour) && !dayIsQuiet
        if store.wasKept(hour, on: day) {
          // A prayed hour is shown as prayed even when nothing was owed —
          // the notice is what a quiet Sunday suppresses, not the office.
          cells.append(.kept)
          if required { keptCount += 1 }
        } else {
          cells.append(required ? .notKept : .notRequired)
        }
      }
      days.append(KeptHoursDay(date: day, cells: cells))
    }

    let denominator =
      (sundaysCount ? 7 : 6)
      * LittleHour.allCases.filter(enabled).count

    return KeptHoursWeek(days: days, denominator: denominator, keptCount: keptCount)
  }

  /// Sunday-based, matching `ObservedDaysAggregator` and the grid's Sun…Sat
  /// columns. Computed from the weekday component rather than relying on the
  /// calendar's `firstWeekday`, which varies by locale.
  static func startOfWeek(for date: Date, calendar: Calendar = .current) -> Date {
    let startOfDay = calendar.startOfDay(for: date)
    let weekday = calendar.component(.weekday, from: startOfDay)
    return calendar.date(byAdding: .day, value: -(weekday - 1), to: startOfDay) ?? startOfDay
  }
}
