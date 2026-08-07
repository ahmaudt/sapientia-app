import XCTest

@testable import sapientia

final class OrdinariateCalendarTests: XCTestCase {

  private let calendar = OrdinariateCalendar()

  private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = 12
    return Calendar(identifier: .gregorian).date(from: components)!
  }

  // MARK: - Easter computus

  func testEasterComputusKnownYears() {
    XCTAssertEqual(OrdinariateCalendar.easter(year: 2024), MonthDay(month: 3, day: 31))
    XCTAssertEqual(OrdinariateCalendar.easter(year: 2025), MonthDay(month: 4, day: 20))
    XCTAssertEqual(OrdinariateCalendar.easter(year: 2026), MonthDay(month: 4, day: 5))
    XCTAssertEqual(OrdinariateCalendar.easter(year: 2035), MonthDay(month: 3, day: 25))
  }

  // MARK: - Mockup anchor date (must match design exactly)

  func testMockupDateFridayAfterTrinityNine() {
    let day = calendar.day(for: date(2026, 8, 7))
    XCTAssertEqual(day.dayName, "Friday after Trinity IX")
    XCTAssertEqual(
      day.commemorationText, "Commemoration of S. Sixtus II, Bishop & Martyr")
    XCTAssertTrue(
      day.collect.text.hasPrefix(
        "Grant to us, Lord, we beseech thee, the spirit to think and do always such things as are right"
      ),
      "Unexpected collect: \(day.collect.text.prefix(80))")
  }

  func testTrinityNinthSunday() {
    let day = calendar.day(for: date(2026, 8, 2))
    XCTAssertEqual(day.dayName, "Trinity IX")
    XCTAssertNil(day.commemorationText)
  }

  func testWeekdayInheritsSundayCollect() {
    let sunday = calendar.day(for: date(2026, 8, 2))
    let friday = calendar.day(for: date(2026, 8, 7))
    XCTAssertEqual(sunday.collect.text, friday.collect.text)
  }

  // MARK: - Late Trinity season (2026)

  func testTrinityTwentyFour2026() {
    XCTAssertEqual(calendar.day(for: date(2026, 11, 15)).dayName, "Trinity XXIV")
  }

  func testChristTheKing2026() {
    let day = calendar.day(for: date(2026, 11, 22))
    XCTAssertEqual(day.dayName, "Christ the King")
    XCTAssertFalse(day.collect.text.isEmpty)
  }

  // MARK: - Early Easter year (2035): Epiphany overflow rule

  func testEpiphanyOverflowSundays2035() {
    // Easter 2035 = Mar 25, Trinity = May 20, Advent I = Dec 2.
    // Nov 11 = Trinity XXV, Nov 18 = Trinity XXVI (Epiphany collects reused),
    // Nov 25 = Christ the King.
    let trinity25 = calendar.day(for: date(2035, 11, 11))
    XCTAssertEqual(trinity25.dayName, "Trinity XXV")
    XCTAssertTrue(
      trinity25.collect.text.hasPrefix(
        "Almighty and everlasting God, mercifully look upon our infirmities"),
      "Trinity XXV should reuse the Epiphany III collect, got: \(trinity25.collect.text.prefix(60))"
    )

    let trinity26 = calendar.day(for: date(2035, 11, 18))
    XCTAssertEqual(trinity26.dayName, "Trinity XXVI")
    XCTAssertFalse(trinity26.collect.text.isEmpty)

    XCTAssertEqual(calendar.day(for: date(2035, 11, 25)).dayName, "Christ the King")
  }

  func testEverySundayOfDecadeHasACollect() {
    // Sweep all Sundays 2024-2033: the engine must never come up empty.
    let gregorian = Calendar(identifier: .gregorian)
    var current = date(2024, 1, 7)  // a Sunday
    let end = date(2033, 12, 31)
    while current <= end {
      let day = calendar.day(for: current)
      XCTAssertFalse(
        day.collect.text.isEmpty,
        "Empty collect on \(current) (\(day.dayName))")
      current = gregorian.date(byAdding: .day, value: 7, to: current)!
    }
  }

  // MARK: - Fixed feasts and seasons

  func testChristmasDay() {
    let day = calendar.day(for: date(2026, 12, 25))
    XCTAssertEqual(day.dayName, "Christmas Day")
    XCTAssertTrue(
      day.collect.text.hasPrefix("Almighty God, who hast given us thy only-begotten Son"))
  }

  func testAshWednesday() {
    let day = calendar.day(for: date(2026, 2, 18))
    XCTAssertEqual(day.dayName, "Ash Wednesday")
    XCTAssertTrue(
      day.collect.text.hasPrefix(
        "Almighty and everlasting God, who hatest nothing that thou hast made"))
  }

  func testAdventSunday() {
    let day = calendar.day(for: date(2026, 11, 29))
    XCTAssertEqual(day.dayName, "Advent I")
    XCTAssertTrue(
      day.collect.text.hasPrefix("Almighty God, give us grace that we may cast away"))
  }

  func testPrincipalFeastOverridesSunday() {
    // 2026-11-01 is a Sunday AND All Saints' Day: the principal feast wins
    // the name and the collect.
    let day = calendar.day(for: date(2026, 11, 1))
    XCTAssertEqual(day.dayName, "All Saints' Day")
    XCTAssertTrue(
      day.collect.text.hasPrefix(
        "O Almighty God, who hast knit together thine elect"))
  }

  func testEasterDay() {
    let day = calendar.day(for: date(2026, 4, 5))
    XCTAssertEqual(day.dayName, "Easter Day")
  }
}
