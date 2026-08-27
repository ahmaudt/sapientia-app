import XCTest

@testable import sapientia

/// Task 2 — composing an hour into its ordered reader pages.
///
/// The page *count* is load-bearing: screen 26's footer reads "1 of 5", which
/// only holds if the chapter and the collect share one page. An earlier draft
/// of this plan kept them separate and asserted 5 anyway; these tests exist so
/// that contradiction cannot come back.
final class OfficeSequenceTests: XCTestCase {

  private var sequence: OfficeSequence!

  /// Noon, gregorian, fixed zone — dates never straddle a day boundary and
  /// weekday indices are stable wherever this runs.
  private static func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Edmonton")!
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = 12
    return calendar.date(from: components)!
  }

  // Easter 2026 falls on 5 April; Whitsunday 24 May; Trinity Sunday 31 May.
  private static let inEastertide = date(2026, 4, 20)  // Monday of Easter III
  private static let inWhitsuntide = date(2026, 5, 26)  // Tuesday after Whitsunday
  private static let inTrinitytide = date(2026, 8, 7)  // Friday after Trinity IX
  private static let inAdvent = date(2026, 12, 7)  // Monday after Advent I
  private static let aSunday = date(2026, 8, 9)

  override func setUp() {
    super.setUp()
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Edmonton")!
    sequence = OfficeSequence(calendar: calendar)
  }

  override func tearDown() {
    sequence = nil
    super.tearDown()
  }

  // MARK: - Season fixtures
  // Assert the premise before relying on it, so a calendar change surfaces
  // here rather than as a baffling failure in the devotion tests below.

  func testFixtureDatesFallInTheSeasonsTheyClaim() {
    let liturgy = OrdinariateCalendar()
    XCTAssertEqual(liturgy.day(for: Self.inEastertide).season, .eastertide)
    XCTAssertEqual(liturgy.day(for: Self.inWhitsuntide).season, .whitsuntide)
    XCTAssertEqual(liturgy.day(for: Self.inTrinitytide).season, .trinitytide)
    XCTAssertEqual(liturgy.day(for: Self.inAdvent).season, .advent)
  }

  // MARK: - Page counts

  func testTerceAndNoneAreFivePagesAndSextIsSix() {
    XCTAssertEqual(sequence.pages(for: .terce, on: Self.inTrinitytide).count, 5)
    XCTAssertEqual(sequence.pages(for: .nones, on: Self.inTrinitytide).count, 5)
    XCTAssertEqual(sequence.pages(for: .sext, on: Self.inTrinitytide).count, 6)
  }

  func testPageOrder() {
    let terce = sequence.pages(for: .terce, on: Self.inTrinitytide)
    guard case .opening = terce[0] else { return XCTFail("page 0 should be the opening") }
    for index in 1...3 {
      guard case .psalm = terce[index] else {
        return XCTFail("page \(index) should be a psalm")
      }
    }
    guard case .chapterAndCollect = terce[4] else {
      return XCTFail("page 4 should be chapter and collect")
    }

    // Sext is the same, shifted one by its devotion.
    let sext = sequence.pages(for: .sext, on: Self.inTrinitytide)
    guard case .devotion = sext[0] else { return XCTFail("Sext page 0 should be the devotion") }
    guard case .opening = sext[1] else { return XCTFail("Sext page 1 should be the opening") }
  }

  func testChapterAndCollectIsAlwaysTheLastPageAndNeverSplit() {
    for hour in LittleHour.allCases {
      let pages = sequence.pages(for: hour, on: Self.inTrinitytide)
      guard case .chapterAndCollect = pages.last else {
        return XCTFail("\(hour.rawValue) does not end on chapter-and-collect")
      }
      let finals = pages.filter {
        if case .chapterAndCollect = $0 { return true } else { return false }
      }
      XCTAssertEqual(finals.count, 1, "\(hour.rawValue) should have exactly one such page")
    }
  }

  // MARK: - The devotion before Sext

  func testSextOpensWithTheReginaCoeliThroughEastertideAndWhitsuntide() {
    for date in [Self.inEastertide, Self.inWhitsuntide] {
      guard case .devotion(let devotion, _) = sequence.pages(for: .sext, on: date)[0] else {
        return XCTFail("expected a devotion page")
      }
      XCTAssertEqual(devotion.title, "Regina Coeli")
    }
  }

  func testSextOpensWithTheAngelusOutsideThatSeason() {
    for date in [Self.inTrinitytide, Self.inAdvent] {
      guard case .devotion(let devotion, _) = sequence.pages(for: .sext, on: date)[0] else {
        return XCTFail("expected a devotion page")
      }
      XCTAssertEqual(devotion.title, "The Angelus")
    }
  }

  func testTerceAndNoneNeverCarryADevotion() {
    for hour in [LittleHour.terce, .nones] {
      for date in [Self.inEastertide, Self.inTrinitytide] {
        let devotions = sequence.pages(for: hour, on: date).filter {
          if case .devotion = $0 { return true } else { return false }
        }
        XCTAssertTrue(devotions.isEmpty, "\(hour.rawValue) should have no devotion")
      }
    }
  }

  // MARK: - Chapter rotation

  func testFridaySelectsTheFridayChapter() {
    guard
      case .chapterAndCollect(let final) = sequence.pages(for: .terce, on: Self.inTrinitytide).last
    else { return XCTFail("no final page") }
    XCTAssertEqual(final.chapter.reference, "Philippians 2:2b-4")
  }

  func testSundaySelectsChapterIndexZero() {
    guard case .chapterAndCollect(let final) = sequence.pages(for: .terce, on: Self.aSunday).last
    else { return XCTFail("no final page") }
    XCTAssertEqual(final.chapter.reference, "1 John 4:16")
  }

  // MARK: - The final page's contents

  func testFinalPageCarriesEveryRequiredText() {
    for hour in LittleHour.allCases {
      guard
        case .chapterAndCollect(let final) = sequence.pages(for: hour, on: Self.inTrinitytide).last
      else { return XCTFail("\(hour.rawValue) has no final page") }

      XCTAssertFalse(final.introVersicle.isEmpty, "\(hour.rawValue) lost the collect intro")
      XCTAssertEqual(final.introVersicle[0].text, "O Lord hear our prayer.")
      XCTAssertFalse(final.faithfulDeparted.isEmpty, "\(hour.rawValue) lost the faithful departed")
      XCTAssertTrue(final.faithfulDeparted.contains("rest in peace"))
      XCTAssertFalse(final.conclusion.isEmpty, "\(hour.rawValue) lost the conclusion")
      XCTAssertEqual(final.conclusion.last?.text, "Thanks be to God.")
    }
  }

  func testCollectOptionsEndWithTheCollectOfTheDay() {
    guard
      case .chapterAndCollect(let terce) = sequence.pages(for: .terce, on: Self.inTrinitytide).last
    else { return XCTFail("no final page") }
    // Terce's own collect, then the day's.
    XCTAssertEqual(terce.collects.count, 2)
    XCTAssertEqual(terce.collects[0].title, "The Collect")
    XCTAssertEqual(terce.collects[1].title, "Or the Collect of the Day")

    guard
      case .chapterAndCollect(let sext) = sequence.pages(for: .sext, on: Self.inTrinitytide).last
    else { return XCTFail("no final page") }
    // Sext's two, then the day's.
    XCTAssertEqual(sext.collects.count, 3)
    XCTAssertEqual(sext.collects[1].title, "Or")
    XCTAssertEqual(sext.collects[2].title, "Or the Collect of the Day")
  }

  func testCollectOfTheDayMatchesTheKalendar() {
    let expected = OrdinariateCalendar().day(for: Self.inTrinitytide).collect.text
    guard
      case .chapterAndCollect(let final) = sequence.pages(for: .terce, on: Self.inTrinitytide).last
    else { return XCTFail("no final page") }
    XCTAssertEqual(final.collects.last?.text, expected)
  }

  // MARK: - Psalms

  func testPsalmPagesReportTheirPosition() {
    let pages = sequence.pages(for: .terce, on: Self.inTrinitytide)
    let psalms = pages.compactMap { page -> (Psalm, Int, Int)? in
      if case .psalm(let psalm, let index, let total, _) = page {
        return (psalm, index, total)
      }
      return nil
    }
    XCTAssertEqual(psalms.count, 3)
    XCTAssertEqual(psalms.map(\.1), [1, 2, 3])
    XCTAssertTrue(psalms.allSatisfy { $0.2 == 3 })
    XCTAssertEqual(psalms.map { $0.0.number }, ["Psalm 120", "Psalm 121", "Psalm 122"])
  }

  /// The Gloria closing a psalm keeps the pointing, matching the pointed
  /// verses above it. This is deliberately a *different* form from the one
  /// that answers the opening versicle.
  func testEveryPsalmPageCarriesThePointedGloria() {
    let expected = """
      Glory be to the Father, and to the Son, * and to the Holy Ghost.
      As it was in the beginning, is now and ever shall be, * world without end. Amen.
      """
    for hour in LittleHour.allCases {
      for page in sequence.pages(for: hour, on: Self.inTrinitytide) {
        guard case .psalm(_, _, _, let gloria) = page else { continue }
        XCTAssertEqual(gloria, expected, "\(hour.rawValue): the psalm Gloria must stay pointed")
        XCTAssertEqual(
          gloria.split(separator: "\n").count, 2, "it is set as two pointed lines")
      }
    }
  }

  /// The Gloria answers the opening versicle as well as closing each psalm —
  /// the traditional shape of every hour. The source pages print only the
  /// psalm ones, so this is asserted explicitly to keep it from being "tidied"
  /// away later by someone comparing against prayer.covert.org.
  func testTheGloriaAlsoAnswersTheOpeningVersicle() {
    for hour in LittleHour.allCases {
      let pages = sequence.pages(for: hour, on: Self.inTrinitytide)
      guard
        let opening = pages.first(where: {
          if case .opening = $0 { return true } else { return false }
        }),
        case .opening(let responsory, let gloria, _) = opening
      else { return XCTFail("\(hour.rawValue) has no opening page") }

      XCTAssertEqual(responsory.last?.text, "O LORD, make haste to help us.")
      XCTAssertEqual(gloria.count, 2, "\(hour.rawValue): the Gloria follows the opening versicle")
      XCTAssertEqual(gloria[0].speaker, "Officiant")
      XCTAssertEqual(gloria[1].speaker, "People")
    }
  }

  /// The opening Gloria is said, not sung from the pointing, so it carries no
  /// asterisks — unlike the one closing each psalm.
  func testTheOpeningGloriaCarriesNoPointingMarks() {
    guard case .opening(_, let gloria, _) = sequence.pages(for: .terce, on: Self.inTrinitytide)[0]
    else { return XCTFail("expected the opening page") }
    XCTAssertFalse(gloria.contains { $0.text.contains("*") })

    guard
      case .psalm(_, _, _, let psalmGloria) = sequence.pages(
        for: .terce, on: Self.inTrinitytide)[1]
    else { return XCTFail("expected a psalm page") }
    XCTAssertTrue(psalmGloria.contains("*"), "the psalm Gloria keeps its pointing")
  }

  // MARK: - Degradation

  func testAnEmptyDatasetProducesNoPagesRatherThanCrashing() {
    let barren = OfficeSequence(dataset: .empty)
    XCTAssertTrue(barren.pages(for: .terce, on: Self.inTrinitytide).isEmpty)
  }
}
