import Foundation

// Row state for the three hours, shared by The Hours screen (Task 7) and the
// Home section (Task 9) so the two can never disagree about which hour is due.

enum LittleHourState: Equatable {
  /// Prayed today.
  case kept
  /// The office owed now — the earliest enabled hour whose time has passed
  /// and which has not been prayed.
  case current
  /// Its time has not come yet.
  case upcoming
  /// Switched off in the reminders screen. Still listed and still prayable;
  /// it simply asks nothing of the user.
  case disabled
}

struct LittleHourRow: Equatable {
  let hour: LittleHour
  /// "Midmorning — Terce".
  let title: String
  /// "Psalms 120, 121, 122 · about 9:00".
  let caption: String
  let state: LittleHourState
  /// "Prayed 9:04" when kept, otherwise the hour's time.
  let trailingLabel: String

  /// Always true. The hours are not tied to the clock — screen 25 says the
  /// office waits until you come to it — so a kept, disabled or not-yet-due
  /// hour all still open.
  var isTappable: Bool { true }
}

enum LittleHoursRowModel {

  /// The three rows in clock order, for a day as at a moment.
  ///
  /// `now` is passed in rather than read from `Date()` so the caller can drive
  /// it from a `TimelineView` (keeping the screen live as an hour arrives) and
  /// so tests can place the clock precisely.
  static func rows(
    on day: Date,
    now: Date,
    store: KeptHoursStore,
    calendar: Calendar = .current,
    dataset: LittleHoursDataset = .loadBundled()
  ) -> [LittleHourRow] {
    let ordered = LittleHour.allCases.sorted {
      LittleHoursSettings.minutes(for: $0) < LittleHoursSettings.minutes(for: $1)
    }

    let currentHour = currentHour(on: day, now: now, store: store, calendar: calendar)

    return ordered.map { hour in
      let office = dataset.office(hour)
      let minutes = LittleHoursSettings.minutes(for: hour)
      let kept = store.wasKept(hour, on: day)

      let state: LittleHourState
      if kept {
        state = .kept
      } else if !LittleHoursSettings.isEnabled(hour) {
        state = .disabled
      } else if hour == currentHour {
        state = .current
      } else {
        state = .upcoming
      }

      let time = timeLabel(minutes)
      return LittleHourRow(
        hour: hour,
        title: office?.displayTitle ?? hour.rawValue.capitalized,
        caption: "\(office?.psalmSummary ?? "") · about \(time)",
        state: state,
        trailingLabel: kept
          ? "Prayed \(store.keptTimeLabel(hour, on: day) ?? time)"
          : time)
    }
  }

  /// The **earliest** enabled, unkept hour whose time has arrived.
  ///
  /// Earliest rather than most recent, so a missed Terce stays the office owed
  /// even once Sext's time has passed; hours accumulate in order instead of
  /// silently rolling forward.
  static func currentHour(
    on day: Date,
    now: Date,
    store: KeptHoursStore,
    calendar: Calendar = .current
  ) -> LittleHour? {
    let minutesNow = minutesSinceMidnight(now, calendar: calendar)
    // Only meaningful for the day in question: yesterday's office is not owed
    // today, and tomorrow's has not arrived.
    guard calendar.isDate(day, inSameDayAs: now) else { return nil }

    return
      LittleHour.allCases
      .filter { LittleHoursSettings.isEnabled($0) && !store.wasKept($0, on: day) }
      .filter { LittleHoursSettings.minutes(for: $0) <= minutesNow }
      .min { LittleHoursSettings.minutes(for: $0) < LittleHoursSettings.minutes(for: $1) }
  }

  static func minutesSinceMidnight(_ date: Date, calendar: Calendar) -> Int {
    let components = calendar.dateComponents([.hour, .minute], from: date)
    return (components.hour ?? 0) * 60 + (components.minute ?? 0)
  }

  /// "9:00", "13:37" — 24-hour, matching the design and `KeptHoursStore`.
  static func timeLabel(_ minutes: Int) -> String {
    String(format: "%d:%02d", minutes / 60, minutes % 60)
  }
}
