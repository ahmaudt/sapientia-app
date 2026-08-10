import Foundation

/// The state of a single day cell in the observance grid.
enum KeptDayState: Equatable {
  case kept
  case partKept
  case notHeld
}

/// One row of the observance grid — a Sunday-based week named by the
/// liturgical day that governs it, with seven cells (Sunday…Saturday).
struct ObservedWeek: Equatable {
  let governingSundayName: String
  let days: [KeptDayState]
}

struct ObservedDaysAggregation: Equatable {
  let totalDaysObserved: Int
  let longestRun: Int
  /// Weeks with at least one kept day, newest first.
  let weeks: [ObservedWeek]
}

/// Counts days kept (any calendar day overlapped by a completed session),
/// grouped into liturgical weeks named by their governing Sunday. The same
/// injected `Calendar` drives both day-bucketing and the `OrdinariateCalendar`
/// used for naming, so day membership and week names never disagree at a
/// boundary. Mirrors `WeeklySessionAggregator`'s shape; pure and synchronous.
enum ObservedDaysAggregator {

  /// Drops active (nil-end) sessions and maps to intervals — the caller's
  /// bridge from `BlockedProfileSession` pairs.
  static func intervals(
    from pairs: [(start: Date, end: Date?)]
  ) -> [WeeklySessionInterval] {
    pairs.compactMap { pair in
      guard let end = pair.end else { return nil }
      return WeeklySessionInterval(startTime: pair.start, endTime: end)
    }
  }

  static func aggregate(
    sessions: [WeeklySessionInterval],
    calendar: Calendar = .current
  ) -> ObservedDaysAggregation {
    let liturgy = OrdinariateCalendar(calendar: calendar)

    // 1. Distinct kept days (day-start dates in the injected calendar).
    var keptDayStarts: Set<Date> = []
    for session in sessions {
      var day = calendar.startOfDay(for: session.startTime)
      let lastDay = calendar.startOfDay(for: session.endTime)
      while day <= lastDay {
        keptDayStarts.insert(day)
        guard let next = calendar.date(byAdding: .day, value: 1, to: day) else { break }
        day = next
      }
    }

    let sortedDays = keptDayStarts.sorted()

    // 2. Longest consecutive run of kept days.
    var longestRun = 0
    var currentRun = 0
    var previous: Date?
    for day in sortedDays {
      if let previous, calendar.date(byAdding: .day, value: 1, to: previous) == day {
        currentRun += 1
      } else {
        currentRun = 1
      }
      longestRun = max(longestRun, currentRun)
      previous = day
    }

    // 3. Group kept days into Sunday-based weeks.
    var weekBuckets: [Date: Set<Date>] = [:]
    for day in sortedDays {
      let sunday = governingSunday(for: day, calendar: calendar)
      weekBuckets[sunday, default: []].insert(day)
    }

    let weeks =
      weekBuckets.keys
      .sorted(by: >)  // newest week first
      .map { sunday -> ObservedWeek in
        let kept = weekBuckets[sunday] ?? []
        let days = (0..<7).map { offset -> KeptDayState in
          guard let cell = calendar.date(byAdding: .day, value: offset, to: sunday)
          else { return .notHeld }
          return kept.contains(cell) ? .kept : .notHeld
        }
        return ObservedWeek(
          governingSundayName: liturgy.day(for: sunday).dayName,
          days: days
        )
      }

    return ObservedDaysAggregation(
      totalDaysObserved: keptDayStarts.count,
      longestRun: longestRun,
      weeks: weeks
    )
  }

  /// The Sunday on or before `day` (start-of-day), regardless of the
  /// calendar's `firstWeekday` — the observance grid is always Sunday-first.
  private static func governingSunday(for day: Date, calendar: Calendar) -> Date {
    let weekday = calendar.component(.weekday, from: day)  // 1 = Sunday (Gregorian)
    return calendar.date(byAdding: .day, value: -(weekday - 1), to: day) ?? day
  }
}
