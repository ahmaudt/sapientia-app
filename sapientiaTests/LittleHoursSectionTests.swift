import XCTest

@testable import sapientia

/// Task 9 — the Home section.
///
/// The section is a condensed view of the same rows The Hours screen shows,
/// so most of its behaviour is asserted in `TheHoursViewTests`. What matters
/// here is that it really is the *same* derivation, not a second copy that
/// can drift.
final class LittleHoursSectionTests: XCTestCase {

  private var calendar: Calendar!
  private var store: KeptHoursStore!

  private let day = LittleHoursSectionTests.makeDate(2026, 8, 27)

  private static func makeDate(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0) -> Date
  {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Edmonton")!
    var components = DateComponents()
    components.year = y
    components.month = m
    components.day = d
    components.hour = h
    components.minute = min
    return calendar.date(from: components)!
  }

  private func at(_ hour: Int, _ minute: Int = 0) -> Date {
    Self.makeDate(2026, 8, 27, hour, minute)
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

  /// The guarantee that matters: Home and The Hours read from one function.
  func testHomeRowsAreIdenticalToTheHoursScreenRows() {
    store.record(.terce, on: day, at: at(9, 4))

    let now = at(12, 30)
    let hoursScreen = LittleHoursRowModel.rows(
      on: day, now: now, store: store, calendar: calendar)
    let homeSection = LittleHoursSectionModel.rows(
      on: day, now: now, store: store, calendar: calendar)

    XCTAssertEqual(homeSection, hoursScreen)
  }

  func testTheSectionSummarisesTheDay() {
    XCTAssertEqual(
      LittleHoursSectionModel.summary(on: day, now: at(7), store: store, calendar: calendar),
      "None kept yet · Terce at 9:00")
  }

  func testSummaryNamesTheOfficeOwedNow() {
    store.record(.terce, on: day, at: at(9, 4))
    XCTAssertEqual(
      LittleHoursSectionModel.summary(on: day, now: at(12, 30), store: store, calendar: calendar),
      "One of three kept · Sext now")
  }

  func testSummaryWhenTheDayIsComplete() {
    for hour in LittleHour.allCases {
      store.record(hour, on: day, at: at(9))
    }
    XCTAssertEqual(
      LittleHoursSectionModel.summary(on: day, now: at(16), store: store, calendar: calendar),
      "All three hours kept.")
  }

  func testSummaryCountsOnlyEnabledHours() {
    LittleHoursSettings.setEnabled(false, for: .nones)
    store.record(.terce, on: day, at: at(9))
    store.record(.sext, on: day, at: at(12))
    // Two of two, phrased as English rather than "All two hours kept."
    XCTAssertEqual(
      LittleHoursSectionModel.summary(on: day, now: at(16), store: store, calendar: calendar),
      "Both hours kept.")
  }

  func testSummaryWithASingleEnabledHour() {
    for hour in [LittleHour.terce, .sext] {
      LittleHoursSettings.setEnabled(false, for: hour)
    }
    store.record(.nones, on: day, at: at(15))
    XCTAssertEqual(
      LittleHoursSectionModel.summary(on: day, now: at(16), store: store, calendar: calendar),
      "The hour is kept.")
  }

  func testSummaryWhenEveryHourIsSwitchedOff() {
    for hour in LittleHour.allCases {
      LittleHoursSettings.setEnabled(false, for: hour)
    }
    XCTAssertEqual(
      LittleHoursSectionModel.summary(on: day, now: at(12), store: store, calendar: calendar),
      "No hours are set.")
  }
}
