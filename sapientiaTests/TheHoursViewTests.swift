import XCTest

@testable import sapientia

/// Task 7 — the row states on The Hours screen (and, via the same function,
/// the Home section in Task 9).
final class TheHoursViewTests: XCTestCase {

  private var calendar: Calendar!
  private var store: KeptHoursStore!

  private let day = TheHoursViewTests.makeDate(2026, 8, 27)

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

  private func rows(now: Date) -> [LittleHourRow] {
    LittleHoursRowModel.rows(on: day, now: now, store: store, calendar: calendar)
  }

  private func row(_ hour: LittleHour, now: Date) -> LittleHourRow {
    rows(now: now).first { $0.hour == hour }!
  }

  // MARK: - Shape

  func testThereIsARowForEveryHourInClockOrder() {
    let all = rows(now: at(7))
    XCTAssertEqual(all.map(\.hour), [.terce, .sext, .nones])
    XCTAssertEqual(
      all.map(\.title), ["Midmorning — Terce", "Midday — Sext", "Midafternoon — None"])
  }

  func testCaptionNamesThePsalmsAndTheHour() {
    XCTAssertEqual(row(.terce, now: at(7)).caption, "Psalms 120, 121, 122 · about 9:00")
    XCTAssertEqual(row(.sext, now: at(7)).caption, "Psalms 123, 124, 125 · about 12:00")
  }

  func testCaptionFollowsAnEditedTime() {
    LittleHoursSettings.setMinutes(13 * 60 + 37, for: .sext)
    XCTAssertEqual(row(.sext, now: at(7)).caption, "Psalms 123, 124, 125 · about 13:37")
  }

  // MARK: - State

  func testBeforeAnyHourArrivesNothingIsCurrent() {
    let all = rows(now: at(7))
    XCTAssertTrue(all.allSatisfy { $0.state == .upcoming })
    XCTAssertEqual(all.map(\.trailingLabel), ["9:00", "12:00", "15:00"])
  }

  func testAKeptHourShowsWhenItWasPrayed() {
    store.record(.terce, on: day, at: at(9, 4))
    let terce = row(.terce, now: at(12, 30))
    XCTAssertEqual(terce.state, .kept)
    XCTAssertEqual(terce.trailingLabel, "Prayed 9:04")
  }

  func testTheDesignsExampleState() {
    // Screen 25: Terce prayed at 9:04, Sext is the one to pray, None waits.
    store.record(.terce, on: day, at: at(9, 4))
    let all = rows(now: at(12, 30))
    XCTAssertEqual(all.map(\.state), [.kept, .current, .upcoming])
    XCTAssertEqual(all[2].trailingLabel, "15:00")
  }

  /// Missed hours stack in order rather than being skipped: at 13:00 with
  /// nothing prayed, the office owed is Terce, not the most recent one.
  func testTheEarliestOverdueHourIsTheCurrentOne() {
    let all = rows(now: at(13))
    XCTAssertEqual(all.map(\.state), [.current, .upcoming, .upcoming])
  }

  func testOnceTheEarliestIsKeptTheNextOverdueBecomesCurrent() {
    store.record(.terce, on: day, at: at(9))
    let all = rows(now: at(13))
    XCTAssertEqual(all.map(\.state), [.kept, .current, .upcoming])
  }

  func testWithEverythingKeptNothingIsCurrent() {
    for hour in LittleHour.allCases {
      store.record(hour, on: day, at: at(9))
    }
    XCTAssertTrue(rows(now: at(16)).allSatisfy { $0.state == .kept })
  }

  func testADisabledHourIsNeverCurrent() {
    LittleHoursSettings.setEnabled(false, for: .terce)
    let all = rows(now: at(13))
    XCTAssertEqual(row(.terce, now: at(13)).state, .disabled)
    // Sext, being the earliest *enabled* overdue hour, takes the current slot.
    XCTAssertEqual(all.first { $0.hour == .sext }!.state, .current)
  }

  func testADisabledHourIsStillListedSoItCanBePrayed() {
    LittleHoursSettings.setEnabled(false, for: .terce)
    XCTAssertEqual(rows(now: at(13)).count, 3)
  }

  /// The hours are not clock-gated: screen 25 says the office waits until you
  /// come to it, so every row opens regardless of state.
  func testEveryRowIsTappableWhateverItsState() {
    store.record(.terce, on: day, at: at(9))
    LittleHoursSettings.setEnabled(false, for: .nones)
    XCTAssertTrue(rows(now: at(13)).allSatisfy(\.isTappable))
  }

  // MARK: - Time crossing

  func testStateFollowsTheClockAcrossAnHourBoundary() {
    // Terce must be kept first, or it would hold the current slot as the
    // earliest overdue hour and Sext could never take it.
    store.record(.terce, on: day, at: at(9))

    XCTAssertEqual(row(.sext, now: at(11, 59)).state, .upcoming)
    XCTAssertEqual(row(.sext, now: at(12, 0)).state, .current)
  }
}
