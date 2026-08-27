import XCTest

@testable import sapientia

/// Task 6 — the reader's presentation logic and its one side effect.
///
/// The view itself is thin; everything asserted here is a pure mapping from
/// `OfficeSequence`'s pages to what the screen shows, plus the Amen action.
final class OfficeReaderTests: XCTestCase {

  private var calendar: Calendar!
  private var sequence: OfficeSequence!
  private var store: KeptHoursStore!

  /// Friday after Trinity IX — the day every mockup screen depicts.
  private let friday = OfficeReaderTests.makeDate(2026, 8, 7)

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

  override func setUp() {
    super.setUp()
    calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Edmonton")!
    sequence = OfficeSequence(calendar: calendar)
    store = KeptHoursStore(calendar: calendar)
    store.reset()
    LittleHoursSettings.reset()
  }

  override func tearDown() {
    store.reset()
    LittleHoursSettings.reset()
    store = nil
    sequence = nil
    calendar = nil
    super.tearDown()
  }

  private func model(_ hour: LittleHour, at index: Int) -> OfficeReaderPage {
    let pages = sequence.pages(for: hour, on: friday)
    return OfficeReaderModel.describe(
      pages[index], at: index, of: pages.count,
      hour: hour, on: friday, calendar: calendar,
      liturgy: OrdinariateCalendar())
  }

  // MARK: - Header

  func testHeaderNamesTheHourAndTheDay() {
    XCTAssertEqual(model(.terce, at: 0).headerLeading, "Terce")
    XCTAssertEqual(model(.sext, at: 0).headerLeading, "Sext")
    XCTAssertEqual(model(.nones, at: 0).headerLeading, "None")

    XCTAssertEqual(model(.terce, at: 0).headerTrailing, "Friday after Trinity IX")
  }

  func testPsalmPagesNameTheirPositionInTheHeader() {
    // Terce: page 0 opening, pages 1-3 psalms.
    XCTAssertEqual(model(.terce, at: 2).headerTrailing, "Psalm 2 of 3")
  }

  func testTheFinalPageNamesTheWeekday() {
    let terce = sequence.pages(for: .terce, on: friday)
    XCTAssertEqual(model(.terce, at: terce.count - 1).headerTrailing, "Friday")
  }

  // MARK: - Footer and progress

  func testOpeningPageCountsThePagesOfTheOffice() {
    XCTAssertEqual(model(.terce, at: 0).footerNote, "1 of 5 · the Psalms follow")
    // Sext's devotion pushes the opening to index 1 and the office to 6 pages.
    XCTAssertEqual(model(.sext, at: 1).footerNote, "2 of 6 · the Psalms follow")
  }

  func testPsalmPagesExplainTheAsterisk() {
    XCTAssertEqual(model(.terce, at: 2).footerNote, "The pause is at the asterisk.")
  }

  // MARK: - The action

  func testEveryPageButTheLastContinues() {
    let pages = sequence.pages(for: .terce, on: friday)
    for index in 0..<(pages.count - 1) {
      XCTAssertEqual(model(.terce, at: index).actionLabel, "Continue", "page \(index)")
      XCTAssertFalse(model(.terce, at: index).isFinal, "page \(index)")
    }
  }

  func testTheLastPageIsAmen() {
    let pages = sequence.pages(for: .terce, on: friday)
    let last = model(.terce, at: pages.count - 1)
    XCTAssertEqual(last.actionLabel, "Amen")
    XCTAssertTrue(last.isFinal)
  }

  func testSextIsSixPagesAndStillEndsInAmen() {
    let pages = sequence.pages(for: .sext, on: friday)
    XCTAssertEqual(pages.count, 6)
    XCTAssertEqual(model(.sext, at: 5).actionLabel, "Amen")
  }

  // MARK: - Completion

  private func completion(onReschedule: @escaping () -> Void) -> OfficeCompletion {
    OfficeCompletion(store: store, reschedule: onReschedule)
  }

  func testAmenRecordsTheHourAndReschedules() {
    var rescheduled = false
    completion { rescheduled = true }
      .amen(.terce, on: friday, at: Self.makeDate(2026, 8, 7, 9, 4))

    XCTAssertTrue(store.wasKept(.terce, on: friday))
    XCTAssertEqual(store.keptTimeLabel(.terce, on: friday), "9:04")
    XCTAssertTrue(rescheduled, "a kept hour must cancel its own pending notice")
  }

  func testLeavingWithoutAmenRecordsNothingAndReschedulesNothing() {
    var rescheduled = false
    _ = completion { rescheduled = true }

    XCTAssertFalse(store.wasKept(.terce, on: friday))
    XCTAssertFalse(rescheduled)
    XCTAssertEqual(store.entryCount, 0)
  }

  /// The reader is opened for a day; a slow Amen must not slide into the next.
  func testAmenAfterMidnightStillRecordsAgainstTheOpenedDay() {
    completion {}
      .amen(.nones, on: friday, at: Self.makeDate(2026, 8, 8, 0, 2))

    XCTAssertTrue(store.wasKept(.nones, on: friday))
    XCTAssertFalse(store.wasKept(.nones, on: Self.makeDate(2026, 8, 8)))
  }

  // MARK: - The final page's contents, in order

  func testFinalPageOrdersItsSectionsAsTheRiteDoes() {
    let pages = sequence.pages(for: .sext, on: friday)
    guard case .chapterAndCollect(let final) = pages.last else {
      return XCTFail("no final page")
    }

    let sections = OfficeReaderModel.finalPageSections(final)
    XCTAssertEqual(
      sections.map(\.kind),
      [
        .chapter, .chapterVersicle, .collectIntro, .collect, .collect, .collect,
        .faithfulDeparted, .conclusion,
      ],
      "the collect intro and the faithful departed must not be dropped — neither appears in the mockup"
    )
  }

  func testAlternateCollectsAreLabelled() {
    let pages = sequence.pages(for: .sext, on: friday)
    guard case .chapterAndCollect(let final) = pages.last else {
      return XCTFail("no final page")
    }
    let collects = OfficeReaderModel.finalPageSections(final).filter { $0.kind == .collect }
    XCTAssertEqual(collects.map(\.title), ["The Collect", "Or", "Or the Collect of the Day"])
  }
}
