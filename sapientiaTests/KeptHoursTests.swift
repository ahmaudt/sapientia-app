import XCTest

@testable import sapientia

/// Task 4 — recording hours as they are prayed, and the week grid that shows it.
final class KeptHoursTests: XCTestCase {

  private var calendar: Calendar!
  private var store: KeptHoursStore!

  private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12, _ minute: Int = 0)
    -> Date
  {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    components.minute = minute
    return calendar.date(from: components)!
  }

  override func setUp() {
    super.setUp()
    calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Edmonton")!
    store = KeptHoursStore(calendar: calendar)
    store.reset()
    LittleHoursSettings.reset()
  }

  override func tearDown() {
    store.reset()
    LittleHoursSettings.reset()
    store = nil
    calendar = nil
    super.tearDown()
  }

  // MARK: - Recording

  func testRecordingAnHourReadsBackItsTime() {
    let day = date(2026, 8, 7)
    store.record(.terce, on: day, at: date(2026, 8, 7, 9, 4))

    XCTAssertTrue(store.wasKept(.terce, on: day))
    XCTAssertEqual(store.keptTimeLabel(.terce, on: day), "9:04")
  }

  func testAnHourNotPrayedIsNotKept() {
    let day = date(2026, 8, 7)
    XCTAssertFalse(store.wasKept(.sext, on: day))
    XCTAssertNil(store.keptTimeLabel(.sext, on: day))
  }

  func testRecordingTwiceOverwritesRatherThanDuplicating() {
    let day = date(2026, 8, 7)
    store.record(.terce, on: day, at: date(2026, 8, 7, 9, 4))
    store.record(.terce, on: day, at: date(2026, 8, 7, 9, 30))

    XCTAssertEqual(store.entryCount, 1)
    XCTAssertEqual(store.keptTimeLabel(.terce, on: day), "9:30")
  }

  func testHoursAreRecordedIndependentlyPerDay() {
    store.record(.terce, on: date(2026, 8, 7), at: date(2026, 8, 7, 9, 0))
    XCTAssertTrue(store.wasKept(.terce, on: date(2026, 8, 7)))
    XCTAssertFalse(store.wasKept(.terce, on: date(2026, 8, 8)))
  }

  /// The reader passes the day it was *opened for*. Reading `Date()` at write
  /// time instead would file a late Amen against tomorrow, leaving today's row
  /// unprayed and tomorrow's kept before its hour arrived.
  func testAnAmenAfterMidnightFilesAgainstTheDayTheOfficeWasOpenedFor() {
    let officeDay = date(2026, 8, 27)
    let amenTapped = date(2026, 8, 28, 0, 2)

    store.record(.nones, on: officeDay, at: amenTapped)

    XCTAssertTrue(store.wasKept(.nones, on: officeDay))
    XCTAssertFalse(store.wasKept(.nones, on: date(2026, 8, 28)))
  }

  // MARK: - Pruning

  func testEntriesOlderThanNinetyDaysArePrunedOnWrite() {
    let today = date(2026, 8, 27)
    let stale = calendar.date(byAdding: .day, value: -91, to: today)!
    let recent = calendar.date(byAdding: .day, value: -89, to: today)!

    store.record(.terce, on: stale, at: stale)
    store.record(.terce, on: recent, at: recent)
    XCTAssertEqual(store.entryCount, 2)

    // A later write triggers the prune.
    store.record(.sext, on: today, at: today)

    XCTAssertFalse(store.wasKept(.terce, on: stale), "91 days old should be pruned")
    XCTAssertTrue(store.wasKept(.terce, on: recent), "89 days old should survive")
    XCTAssertTrue(store.wasKept(.sext, on: today))
  }

  // MARK: - Week aggregation

  private func aggregate(weekOf day: Date) -> KeptHoursWeek {
    KeptHoursAggregator.aggregate(weekOf: day, store: store, calendar: calendar)
  }

  func testWeekRunsSundayToSaturday() {
    // 2026-08-27 is a Thursday; its week begins Sunday 2026-08-23.
    let week = aggregate(weekOf: date(2026, 8, 27))
    XCTAssertEqual(week.days.count, 7)
    XCTAssertEqual(calendar.component(.weekday, from: week.days[0].date), 1)
    XCTAssertEqual(calendar.component(.weekday, from: week.days[6].date), 7)
  }

  func testQuietSundaysAreNotRequiredAndShrinkTheDenominator() {
    // Default: Sundays quiet, all three hours on.
    let week = aggregate(weekOf: date(2026, 8, 27))
    XCTAssertEqual(week.denominator, 18)
    XCTAssertEqual(week.days[0].cells, [.notRequired, .notRequired, .notRequired])
  }

  func testEnablingSundaysRestoresTheFullTwentyOne() {
    LittleHoursSettings.remindsOnSundays = true
    let week = aggregate(weekOf: date(2026, 8, 27))
    XCTAssertEqual(week.denominator, 21)
    XCTAssertEqual(week.days[0].cells, [.notKept, .notKept, .notKept])
  }

  /// The finding that a fixed ×3 would have shipped: with an hour switched
  /// off, a denominator of 18 is a target the user can never reach.
  func testDisablingAnHourShrinksTheDenominatorAndBlanksThatRow() {
    LittleHoursSettings.setEnabled(false, for: .terce)
    let week = aggregate(weekOf: date(2026, 8, 27))

    XCTAssertEqual(week.denominator, 12, "6 weekdays x 2 enabled hours")
    let terceIndex = LittleHour.allCases.firstIndex(of: .terce)!
    for day in week.days {
      XCTAssertEqual(day.cells[terceIndex], .notRequired, "Terce should be inert all week")
    }
  }

  func testKeptHoursAreCountedAgainstTheDenominator() {
    // Twelve kept across the working week, Sundays quiet.
    let sunday = date(2026, 8, 23)
    var kept = 0
    for offset in 1...4 {  // Mon-Thu
      let day = calendar.date(byAdding: .day, value: offset, to: sunday)!
      for hour in LittleHour.allCases {
        store.record(hour, on: day, at: day)
        kept += 1
      }
    }
    XCTAssertEqual(kept, 12)

    let week = aggregate(weekOf: date(2026, 8, 27))
    XCTAssertEqual(week.keptCount, 12)
    XCTAssertEqual(week.denominator, 18)
    XCTAssertEqual(week.caption, "Twelve of eighteen hours kept so far this week.")
  }

  /// Praying on a quiet Sunday is not an error — the *notice* is suppressed,
  /// not the office — so the grid shows it kept. But it stays out of the
  /// ratio, which measures the rule the user actually set. Counting it would
  /// let a diligent week read "Twenty-one of eighteen", which is nonsense.
  func testAnHourKeptBeyondTheRuleShowsInTheGridButNotInTheRatio() {
    let sunday = date(2026, 8, 23)
    store.record(.terce, on: sunday, at: sunday)

    let week = aggregate(weekOf: date(2026, 8, 27))
    XCTAssertEqual(week.days[0].cells[0], .kept, "a prayed hour is shown as prayed")
    XCTAssertEqual(week.keptCount, 0, "but it is not part of the week's rule")
    XCTAssertEqual(week.denominator, 18)
  }

  func testTheRatioCanNeverExceedItsDenominator() {
    LittleHoursSettings.setEnabled(false, for: .terce)
    let sunday = date(2026, 8, 23)
    for offset in 0...6 {
      let day = calendar.date(byAdding: .day, value: offset, to: sunday)!
      for hour in LittleHour.allCases {
        store.record(hour, on: day, at: day)
      }
    }

    let week = aggregate(weekOf: date(2026, 8, 27))
    XCTAssertEqual(week.denominator, 12)
    XCTAssertEqual(week.keptCount, 12, "every required hour kept, and no more")
    XCTAssertLessThanOrEqual(week.keptCount, week.denominator)
  }
}
