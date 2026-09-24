import XCTest

@testable import sapientia

/// Integrity of the bundled sanctorale in `ordinariate-calendar.json`.
///
/// Every collect must be copied from a public-domain book and say which one:
/// an invented or misattributed prayer presented as the Church's text is the
/// failure this dataset exists to prevent. These tests cannot check a text
/// against its book — that is a human audit — but they do refuse an entry
/// that has no text, no source, or a source outside the approved books.
final class SanctoraleDatasetTests: XCTestCase {

  private let sanctorale = LiturgicalDataset.loadBundled().sanctorale

  /// The only books a `collectSource` may cite.
  private let allowedSources = [
    "BCP 1662", "BCP 1928", "BCP 1979 (Rite One)", "Anglican Missal 1921",
  ]

  /// Every fixed-date observance in the North American Ordinariate calendar,
  /// one string per entry, taken from the 2025 and 2026 ORDOs (Canada-only
  /// entries, civil days, Saturday Masses of Our Lady, the O Antiphon and
  /// Christmas octave weekdays, and movable observances excluded).
  private let wholeYear = [
    "1/1", "1/2", "1/3", "1/4", "1/5", "1/6", "1/6", "1/7", "1/12", "1/13", "1/17", "1/20", "1/20",
    "1/21", "1/23", "1/23", "1/24", "1/25", "1/26", "1/27", "1/28", "1/31", "2/2", "2/3", "2/3",
    "2/4", "2/5", "2/6", "2/8", "2/8", "2/10", "2/11", "2/14", "2/17", "2/21", "2/22", "2/27",
    "3/1", "3/3", "3/4", "3/7", "3/8", "3/9", "3/17", "3/18", "3/19", "3/23", "3/25", "4/2",
    "4/4", "4/5", "4/7", "4/13", "4/21", "4/23", "4/24", "4/24", "4/25", "4/28", "4/28", "4/29",
    "4/30", "5/1", "5/2", "5/3", "5/4", "5/10", "5/10", "5/12", "5/12", "5/13", "5/14", "5/15",
    "5/18", "5/19", "5/20", "5/21", "5/22", "5/25", "5/25", "5/26", "5/27", "5/29", "5/31",
    "6/1", "6/2", "6/3", "6/5", "6/6", "6/9", "6/9", "6/11", "6/13", "6/16", "6/19", "6/20",
    "6/21", "6/22", "6/23", "6/23", "6/24", "6/27", "6/28", "6/29", "6/30",
    "7/1", "7/3", "7/5", "7/5", "7/6", "7/9", "7/9", "7/11", "7/13", "7/14", "7/15", "7/16", "7/18",
    "7/20", "7/21", "7/22", "7/23", "7/24", "7/25", "7/26", "7/29", "7/30", "7/31", "8/1", "8/2",
    "8/2", "8/4", "8/5", "8/6", "8/7", "8/7", "8/8", "8/9", "8/10", "8/11", "8/12", "8/13", "8/14",
    "8/15", "8/16", "8/19", "8/20", "8/21", "8/22", "8/23", "8/24", "8/25", "8/25", "8/27", "8/28",
    "8/29", "8/30", "8/31", "9/3", "9/4", "9/5", "9/8", "9/9", "9/12", "9/13", "9/14", "9/15",
    "9/16", "9/17", "9/17", "9/19", "9/19", "9/19", "9/20", "9/21", "9/23", "9/24", "9/26", "9/27",
    "9/28", "9/28", "9/29", "9/30", "10/1", "10/2", "10/4", "10/5", "10/5", "10/6", "10/6", "10/7",
    "10/8", "10/8", "10/9", "10/11", "10/12", "10/13", "10/14", "10/15", "10/16", "10/16", "10/17",
    "10/18", "10/19", "10/20", "10/22", "10/23", "10/24", "10/28", "11/1", "11/2", "11/3", "11/4",
    "11/9", "11/10", "11/11", "11/12", "11/13", "11/15", "11/16", "11/16", "11/17", "11/18",
    "11/18", "11/20", "11/21", "11/22", "11/23", "11/23", "11/23", "11/24", "11/25", "11/30",
    "12/3", "12/4", "12/6", "12/7", "12/8", "12/9", "12/10", "12/11", "12/12", "12/13", "12/14",
    "12/21", "12/23", "12/25", "12/26", "12/27", "12/28", "12/29", "12/31",
  ]

  private func label(_ entry: LiturgicalDataset.Feast) -> String {
    "\(entry.month)/\(entry.day) \(entry.name)"
  }

  /// No entry lacks a collect, so `OrdinariateCalendar`'s fallback to the
  /// seasonal collect for a governing observance is never reached.
  func testEveryEntryHasACompleteCollectFromAnApprovedBook() {
    XCTAssertFalse(sanctorale.isEmpty)
    for entry in sanctorale {
      let collect = entry.collect ?? ""
      XCTAssertTrue(collect.hasSuffix("Amen."), "Collect incomplete: \(label(entry))")
      let source = entry.collectSource ?? ""
      XCTAssertTrue(
        allowedSources.contains { source.hasPrefix($0) },
        "Source not an approved book: \(label(entry)) — \(source)")
    }
  }

  func testTheYearHoldsEveryObservanceInTheOrdo() {
    let present = sanctorale.map { "\($0.month)/\($0.day)" }
    XCTAssertEqual(present.sorted(), wholeYear.sorted())
  }

  // MARK: - The bundled data under the real calendar

  private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    Calendar(identifier: .gregorian).date(
      from: DateComponents(year: year, month: month, day: day, hour: 12))!
  }

  func testMichaelmasOnASundayIsAbrogatedInTheBundledCalendar() {
    let day = OrdinariateCalendar().day(for: date(2030, 9, 29))
    XCTAssertEqual(day.dayName, "Trinity XV")
    XCTAssertNil(day.observance)
  }

  func testOurLadyOfWalsinghamNamesItsWeekdayInTheBundledCalendar() {
    let day = OrdinariateCalendar().day(for: date(2026, 9, 24))
    XCTAssertEqual(day.dayName, "Our Lady of Walsingham")
    XCTAssertEqual(day.observance?.phrase(capitalized: true), "The Feast of Our Lady of Walsingham")
  }

  func testNamesUseTheDatasetsStyleRatherThanTheOrdos() {
    for entry in sanctorale {
      XCTAssertFalse(
        entry.name.hasPrefix("Saint ") || entry.name.hasPrefix("St "),
        "Unconverted name: \(label(entry))")
    }
  }

  func testEveryEntryIsARealDateAndAppearsOnce() {
    let gregorian = Calendar(identifier: .gregorian)
    var seen = Set<String>()
    for entry in sanctorale {
      // 2024 is a leap year, so 29 February is a real date too.
      let components = DateComponents(year: 2024, month: entry.month, day: entry.day)
      XCTAssertTrue(components.isValidDate(in: gregorian), "Not a date: \(label(entry))")
      XCTAssertTrue(seen.insert(label(entry)).inserted, "Duplicate: \(label(entry))")
    }
  }
}
