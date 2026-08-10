import XCTest

@testable import sapientia

final class ObservedDaysAggregatorTests: XCTestCase {

  private func gregorian(_ tzHours: Int = 0) -> Calendar {
    var cal = Calendar(identifier: .gregorian)
    cal.timeZone = TimeZone(secondsFromGMT: tzHours * 3600)!
    return cal
  }

  private func date(_ cal: Calendar, _ y: Int, _ m: Int, _ d: Int, _ h: Int = 12) -> Date {
    var c = DateComponents()
    c.year = y
    c.month = m
    c.day = d
    c.hour = h
    return cal.date(from: c)!
  }

  private func interval(_ cal: Calendar, _ y: Int, _ m: Int, _ d: Int, hours: Double = 1)
    -> WeeklySessionInterval
  {
    let start = date(cal, y, m, d, 9)
    return WeeklySessionInterval(
      startTime: start, endTime: start.addingTimeInterval(hours * 3600))
  }

  // MARK: - Trinity IX week (mockup anchor)

  func testTrinityWeekNamingAndKeptCells() {
    let cal = gregorian()
    // Aug 2 2026 is a Sunday (Trinity IX). Kept Mon/Wed/Fri.
    let sessions = [
      interval(cal, 2026, 8, 3),  // Mon
      interval(cal, 2026, 8, 5),  // Wed
      interval(cal, 2026, 8, 7),  // Fri
    ]
    let result = ObservedDaysAggregator.aggregate(sessions: sessions, calendar: cal)

    XCTAssertEqual(result.totalDaysObserved, 3)
    XCTAssertEqual(result.weeks.count, 1)
    let week = result.weeks[0]
    XCTAssertEqual(week.governingSundayName, "Trinity IX")
    // Sun..Sat: [Sun, Mon✓, Tue, Wed✓, Thu, Fri✓, Sat]
    XCTAssertEqual(
      week.days,
      [.notHeld, .kept, .notHeld, .kept, .notHeld, .kept, .notHeld])
  }

  func testLongestRunAcrossAGap() {
    let cal = gregorian()
    let sessions = [
      interval(cal, 2026, 8, 3),  // Mon
      interval(cal, 2026, 8, 5),  // Wed
      interval(cal, 2026, 8, 6),  // Thu
      interval(cal, 2026, 8, 7),  // Fri (Wed–Fri = run of 3)
    ]
    let result = ObservedDaysAggregator.aggregate(sessions: sessions, calendar: cal)
    XCTAssertEqual(result.totalDaysObserved, 4)
    XCTAssertEqual(result.longestRun, 3)
  }

  // MARK: - Non-Trinity week naming

  func testAdventWeekNaming() {
    let cal = gregorian()
    // Nov 29 2026 is Advent I (Sunday). A kept day that week.
    let result = ObservedDaysAggregator.aggregate(
      sessions: [interval(cal, 2026, 11, 30)], calendar: cal)
    XCTAssertEqual(result.weeks.count, 1)
    XCTAssertEqual(result.weeks[0].governingSundayName, "Advent I")
  }

  // MARK: - Ordering (newest week first)

  func testWeeksOrderedNewestFirst() {
    let cal = gregorian()
    let sessions = [
      interval(cal, 2026, 7, 28),  // Trinity VIII week
      interval(cal, 2026, 8, 4),  // Trinity IX week
    ]
    let result = ObservedDaysAggregator.aggregate(sessions: sessions, calendar: cal)
    XCTAssertEqual(result.weeks.count, 2)
    XCTAssertEqual(result.weeks[0].governingSundayName, "Trinity IX")
    XCTAssertEqual(result.weeks[1].governingSundayName, "Trinity VIII")
  }

  // MARK: - Active-session exclusion

  func testActiveSessionContributesNothing() {
    let cal = gregorian()
    let start = date(cal, 2026, 8, 3, 9)
    let intervals = ObservedDaysAggregator.intervals(
      from: [(start: start, end: nil), (start: start, end: start.addingTimeInterval(3600))])
    XCTAssertEqual(intervals.count, 1, "nil-end (active) session must be dropped")
  }

  // MARK: - Timezone / midnight boundary

  func testOvernightSessionCountsBothDaysInInjectedTimezone() {
    let cal = gregorian(-5)  // fixed non-UTC
    // 23:30 to 00:30 local → spans two calendar days in this timezone.
    let start = date(cal, 2026, 8, 3, 23).addingTimeInterval(30 * 60)
    let session = WeeklySessionInterval(
      startTime: start, endTime: start.addingTimeInterval(3600))
    let result = ObservedDaysAggregator.aggregate(sessions: [session], calendar: cal)
    XCTAssertEqual(result.totalDaysObserved, 2, "overnight session covers two kept days")
  }

  // MARK: - Empty

  func testEmptyInput() {
    let result = ObservedDaysAggregator.aggregate(sessions: [], calendar: gregorian())
    XCTAssertEqual(result.totalDaysObserved, 0)
    XCTAssertEqual(result.longestRun, 0)
    XCTAssertTrue(result.weeks.isEmpty)
  }
}
