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
    // A memorial keeps the temporal name and adds its own line beneath it.
    let day = calendar.day(for: date(2026, 8, 7))
    XCTAssertEqual(day.dayName, "Friday after Trinity IX")
    XCTAssertTrue(
      day.commemorationText?.hasPrefix("The memorial of SS. Sixtus II") == true,
      day.commemorationText ?? "nil")
  }

  func testTrinityNinthSunday() {
    let day = calendar.day(for: date(2026, 8, 2))
    XCTAssertEqual(day.dayName, "Trinity IX")
    XCTAssertNil(day.commemorationText)
    XCTAssertTrue(
      day.collect.text.hasPrefix(
        "Grant to us, Lord, we beseech thee, the spirit to think and do always such things as are right"
      ),
      "Unexpected collect: \(day.collect.text.prefix(80))")
  }

  func testWeekdayWithNoSaintInheritsSundayCollect() {
    // 3 August 2026 keeps no saint in the Ordinariate calendar.
    let sunday = calendar.day(for: date(2026, 8, 2))
    let monday = calendar.day(for: date(2026, 8, 3))
    XCTAssertEqual(monday.dayName, "Monday after Trinity IX")
    XCTAssertNil(monday.observance)
    XCTAssertEqual(sunday.collect.text, monday.collect.text)
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

  // MARK: - Precedence of the saints (injected sanctorale)

  private typealias Entry = LiturgicalDataset.Feast

  /// A calendar whose sanctorale is exactly `entries`, over the bundled
  /// temporale — so precedence is asserted independently of the bundled saints.
  private func calendar(with entries: [Entry]) -> OrdinariateCalendar {
    OrdinariateCalendar(
      dataset: LiturgicalDataset(
        sanctorale: entries, temporale: LiturgicalDataset.loadBundled().temporale))
  }

  private func sundayCollect(_ date: Date) -> String {
    calendar(with: []).day(for: date).collect.text
  }

  func testGivenAWeekdayMemorial_WhenResolved_ThenTheSaintsCollectGovernsUnderTheTemporalName() {
    let dominic = Entry(
      month: 8, day: 8, name: "S. Dominic, Priest", rank: .memorial,
      collect: "O God, who hast vouchsafed to enlighten thy Church…")
    let day = calendar(with: [dominic]).day(for: date(2026, 8, 8))

    XCTAssertEqual(day.dayName, "Saturday after Trinity IX")
    XCTAssertEqual(day.commemorationText, "The memorial of S. Dominic, Priest")
    XCTAssertEqual(day.collect.text, "O God, who hast vouchsafed to enlighten thy Church…")
    XCTAssertEqual(day.observance?.rank, .memorial)
  }

  func testGivenAFeastOnASunday_WhenResolved_ThenItIsAbrogated() {
    let michaelmas = Entry(
      month: 9, day: 29, name: "S. Michael and All Angels", rank: .feast, collect: "Michaelmas")
    let sunday = date(2030, 9, 29)
    let day = calendar(with: [michaelmas]).day(for: sunday)

    XCTAssertEqual(day.dayName, "Trinity XV")
    XCTAssertNil(day.commemorationText)
    XCTAssertNil(day.observance)
    XCTAssertEqual(day.collect.text, sundayCollect(sunday))
  }

  func testGivenAFeastOfTheLordOnASunday_WhenResolved_ThenItDisplacesTheSunday() {
    let transfiguration = Entry(
      month: 8, day: 6, name: "The Transfiguration of Our Lord", rank: .feast,
      isFeastOfTheLord: true, collect: "Transfiguration")
    let day = calendar(with: [transfiguration]).day(for: date(2028, 8, 6))

    XCTAssertEqual(day.dayName, "The Transfiguration of Our Lord")
    XCTAssertEqual(day.collect.text, "Transfiguration")
    XCTAssertNil(day.commemorationText)
  }

  func testGivenASolemnityOnAnOrdinarySunday_WhenResolved_ThenItDisplacesTheSunday() {
    let allSaints = Entry(
      month: 11, day: 1, name: "All Saints' Day", rank: .solemnity, collect: "All Saints")
    XCTAssertEqual(
      calendar(with: [allSaints]).day(for: date(2026, 11, 1)).dayName, "All Saints' Day")
  }

  func testGivenAdventAndLentSundays_WhenEvenASolemnityFalls_ThenTheSundayGoverns() {
    let solemnity = Entry(month: 12, day: 8, name: "A Solemnity", rank: .solemnity, collect: "S")
    let lordFeast = Entry(
      month: 3, day: 17, name: "A Feast of the Lord", rank: .feast, isFeastOfTheLord: true,
      collect: "L")

    let advent = calendar(with: [solemnity]).day(for: date(2030, 12, 8))
    XCTAssertEqual(advent.dayName, "Advent II")
    XCTAssertEqual(advent.collect.text, sundayCollect(date(2030, 12, 8)))
    XCTAssertNil(advent.observance)
    XCTAssertNil(advent.commemorationText)

    let lent = calendar(with: [lordFeast]).day(for: date(2024, 3, 17))
    XCTAssertEqual(lent.dayName, "Lent V")
    XCTAssertNil(lent.observance)
    XCTAssertNil(lent.commemorationText)
  }

  func testGivenALentWeekdayMemorial_WhenResolved_ThenTheSaintsCollectReplacesTheSeasons() {
    let patrick = Entry(
      month: 3, day: 17, name: "S. Patrick, Bishop", rank: .memorial, collect: "P")
    let day = calendar(with: [patrick]).day(for: date(2027, 3, 17))
    XCTAssertEqual(day.collect.text, "P")
    XCTAssertEqual(day.commemorationText, "The memorial of S. Patrick, Bishop")
  }

  func testGivenProtectedDays_WhenASaintFalls_ThenTheTemporaleGoverns() {
    let entries = [
      Entry(month: 3, day: 25, name: "The Annunciation", rank: .solemnity, collect: "A"),
      Entry(month: 4, day: 25, name: "S. Mark, Evangelist", rank: .feast, collect: "M"),
      Entry(month: 2, day: 18, name: "S. Somebody", rank: .memorial, collect: "X"),
      Entry(month: 5, day: 14, name: "S. Other", rank: .memorial, collect: "Y"),
    ]
    let calendar = calendar(with: entries)

    let holyWeek = calendar.day(for: date(2027, 3, 25))
    XCTAssertEqual(holyWeek.dayName, "Thursday in Holy Week")
    XCTAssertNil(holyWeek.observance)

    let octave = calendar.day(for: date(2025, 4, 25))
    XCTAssertNotEqual(octave.collect.text, "M")
    XCTAssertNil(octave.observance)
    XCTAssertNil(octave.commemorationText)

    let ashWednesday = calendar.day(for: date(2026, 2, 18))
    XCTAssertEqual(ashWednesday.dayName, "Ash Wednesday")
    XCTAssertNil(ashWednesday.observance)

    let ascension = calendar.day(for: date(2026, 5, 14))
    XCTAssertEqual(ascension.dayName, "Ascension Day")
    XCTAssertNotEqual(ascension.collect.text, "Y")
    XCTAssertEqual(ascension.observance?.rank, .solemnity)
    XCTAssertEqual(ascension.observance?.phrase(capitalized: true), "Ascension Day")
    XCTAssertNil(ascension.commemorationText)
  }

  func testGivenSeveralEntriesOnADate_WhenResolved_ThenTheHighestRankThenTheFirstListedGoverns() {
    let optional = Entry(
      month: 8, day: 7, name: "S. Cajetan, Priest", rank: .optionalMemorial, collect: "C")
    let memorial = Entry(month: 8, day: 7, name: "S. Sixtus II", rank: .memorial, collect: "S")
    XCTAssertEqual(
      calendar(with: [optional, memorial]).day(for: date(2026, 8, 7)).collect.text, "S")

    let first = Entry(month: 8, day: 7, name: "S. Sixtus II", rank: .optionalMemorial, collect: "1")
    let second = Entry(month: 8, day: 7, name: "S. Cajetan", rank: .optionalMemorial, collect: "2")
    XCTAssertEqual(calendar(with: [first, second]).day(for: date(2026, 8, 7)).collect.text, "1")
  }

  func testGivenAFeastOnAWeekday_WhenResolved_ThenItNamesTheDay() {
    let lawrence = Entry(
      month: 8, day: 10, name: "S. Lawrence, Deacon & Martyr", rank: .feast, collect: "L")
    let day = calendar(with: [lawrence]).day(for: date(2026, 8, 10))
    XCTAssertEqual(day.dayName, "S. Lawrence, Deacon & Martyr")
    XCTAssertNil(day.commemorationText)
    XCTAssertEqual(
      day.observance?.phrase(capitalized: true), "The Feast of S. Lawrence, Deacon & Martyr")
  }

  // MARK: - Observance phrase

  func testObservancePhraseLowercasesALeadingTheAndHonoursTheNoticeName() {
    let transfiguration = Observance(
      name: "The Transfiguration of Our Lord", rank: .feast, isFeastOfTheLord: true)
    XCTAssertEqual(
      transfiguration.phrase(capitalized: false), "the Feast of the Transfiguration of Our Lord")
    XCTAssertEqual(
      Observance(name: "S. Cajetan, Priest", rank: .optionalMemorial).phrase(capitalized: true),
      "The memorial of S. Cajetan, Priest")
    XCTAssertEqual(
      Observance(name: "SS. Peter and Paul, Apostles", rank: .solemnity).phrase(capitalized: false),
      "the Solemnity of SS. Peter and Paul, Apostles")
    XCTAssertEqual(
      Observance(name: "Christmas Day", rank: .solemnity, noticeName: "Christmas Day")
        .phrase(capitalized: false),
      "Christmas Day")
  }
}
