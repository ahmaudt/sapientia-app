import XCTest

@testable import sapientia

/// Task 1 — the bundled Little Hours dataset.
///
/// These assertions are deliberately about *content*, not just structure: the
/// texts are liturgy, and a dropped word or a lost mid-verse asterisk is a
/// defect the user would notice at prayer. `scripts/diff-office-text.py`
/// covers the bulk mechanically; the checks here pin the pieces that have no
/// machine-readable original (the Angelus and Regina Coeli) plus a spot check
/// per hour.
final class LittleHoursDatasetTests: XCTestCase {

  private var dataset: LittleHoursDataset!

  override func setUp() {
    super.setUp()
    dataset = LittleHoursDataset.loadBundled()
  }

  override func tearDown() {
    dataset = nil
    super.tearDown()
  }

  // MARK: - Structure

  func testLoadsThreeOfficesFromTheBundle() {
    XCTAssertEqual(dataset.offices.count, 3)
    for hour in LittleHour.allCases {
      XCTAssertNotNil(dataset.office(hour), "missing office for \(hour.rawValue)")
    }
  }

  func testEachOfficeHasThreePsalmsAThreeVerseHymnAndSevenChapters() {
    for hour in LittleHour.allCases {
      let office = dataset.office(hour)!
      XCTAssertEqual(office.psalms.count, 3, "\(hour.rawValue) psalms")
      XCTAssertEqual(office.hymn.verses.count, 3, "\(hour.rawValue) hymn verses")
      XCTAssertEqual(office.chapters.count, 7, "\(hour.rawValue) chapters")
      for index in 0...6 {
        XCTAssertNotNil(
          office.chapters[String(index)], "\(hour.rawValue) missing chapter \(index)")
      }
    }
  }

  func testOnlySextHasAnAlternateCollect() {
    XCTAssertEqual(dataset.office(.terce)!.collects.count, 1)
    XCTAssertEqual(dataset.office(.sext)!.collects.count, 2)
    XCTAssertEqual(dataset.office(.nones)!.collects.count, 1)
    XCTAssertEqual(dataset.office(.sext)!.collects[1].title, "Or")
  }

  func testOnlySextCarriesTheDevotions() {
    XCTAssertNotNil(dataset.office(.sext)!.angelus)
    XCTAssertNotNil(dataset.office(.sext)!.reginaCoeli)

    for hour in [LittleHour.terce, .nones] {
      XCTAssertNil(dataset.office(hour)!.angelus, "\(hour.rawValue) should have no Angelus")
      XCTAssertNil(
        dataset.office(hour)!.reginaCoeli, "\(hour.rawValue) should have no Regina Coeli")
    }
  }

  func testTheGloriaIsCarriedAsASaidResponsory() {
    XCTAssertEqual(dataset.gloriaVersicles.count, 2)
    XCTAssertEqual(dataset.gloriaVersicles[0].speaker, "Officiant")
    XCTAssertEqual(
      dataset.gloriaVersicles[0].text,
      "Glory be to the Father, and to the Son, and to the Holy Ghost.")
    XCTAssertEqual(dataset.gloriaVersicles[1].speaker, "People")
    XCTAssertEqual(
      dataset.gloriaVersicles[1].text,
      "As it was in the beginning, is now and ever shall be, world without end. Amen.")
    // The pointed source is kept so the text can still be diffed against
    // offices-data.js, but it is not what the office renders.
    XCTAssertTrue(dataset.gloria.contains("*"))
  }

  func testSharedConstantsArePresent() {
    XCTAssertTrue(dataset.gloria.contains("Glory be to the Father"))
    XCTAssertEqual(dataset.collectIntroLay.count, 3)
    XCTAssertEqual(dataset.collectIntroLay[0].text, "O Lord hear our prayer.")
    XCTAssertEqual(dataset.conclusion.count, 2)
    XCTAssertEqual(dataset.conclusion[1].text, "Thanks be to God.")
    XCTAssertTrue(dataset.faithfulDeparted.contains("✠"))
  }

  // MARK: - Verbatim text

  func testPsalm121FirstVerseKeepsItsMidVersePause() {
    let psalm = dataset.office(.terce)!.psalms[1]
    XCTAssertEqual(psalm.number, "Psalm 121")
    XCTAssertEqual(
      psalm.verses[0],
      "I WILL lift up mine eyes unto the hills; * from whence cometh my help?")
  }

  func testEveryPsalmVerseKeepsAnAsterisk() {
    // The pause is structural to pointed psalmody; a verse without one is a
    // transcription slip. Psalm 125's last verse is the sole exception in this
    // set — it carries its asterisk mid-verse too, so the rule holds throughout.
    for hour in LittleHour.allCases {
      for psalm in dataset.office(hour)!.psalms {
        for verse in psalm.verses {
          XCTAssertTrue(
            verse.contains("*"), "\(psalm.number) verse without a pause: \(verse)")
        }
      }
    }
  }

  func testReginaCoeliOpeningLine() {
    let regina = dataset.office(.sext)!.reginaCoeli!
    XCTAssertEqual(regina.title, "Regina Coeli")
    XCTAssertEqual(regina.lines[0].text, "O Queen of heaven, be joyful, alleluia;")
    XCTAssertTrue(regina.collect.contains("by the resurrection of thy Son Jesus Christ"))
  }

  func testAngelusCollectKeepsItsCross() {
    let angelus = dataset.office(.sext)!.angelus!
    XCTAssertEqual(angelus.title, "The Angelus")
    XCTAssertEqual(angelus.lines[0].text, "The Angel of the Lord announced unto Mary.")
    XCTAssertTrue(
      angelus.collect.contains("by his ✠ Cross and Passion"),
      "the Angelus collect lost its cross: \(angelus.collect)")
  }

  func testOneLineFromEachHymn() {
    XCTAssertTrue(
      dataset.office(.terce)!.hymn.verses[0].hasPrefix("Come Holy Ghost, with God the Son,"))
    XCTAssertEqual(dataset.office(.terce)!.hymn.latin, "Nunc Sancte nobis Spiritus")

    XCTAssertTrue(
      dataset.office(.sext)!.hymn.verses[0].hasPrefix("O GOD of truth, O Lord of might,"))
    XCTAssertEqual(dataset.office(.sext)!.hymn.latin, "Rector potens, verax Deus")

    XCTAssertTrue(
      dataset.office(.nones)!.hymn.verses[0].hasPrefix("O God, creation's secret force,"))
    XCTAssertEqual(dataset.office(.nones)!.hymn.latin, "Rerum Deus tenax vigor")
  }

  func testFridayChapterForTerceMatchesTheDesign() {
    // Screen 28 shows the Friday set. Friday is weekday index 5.
    let chapter = dataset.office(.terce)!.chapters["5"]!
    XCTAssertEqual(chapter.reference, "Philippians 2:2b-4")
    XCTAssertEqual(
      chapter.text,
      "Be of the same mind, having the same love, being in full accord and of one mind. Do nothing from selfishness or conceit, but in humility count others better than yourselves. Let each of you look not only to his own interests, but also to the interests of others."
    )
    XCTAssertEqual(chapter.versicle, "All the paths of the Lord are mercy and truth;")
    XCTAssertEqual(chapter.response, "Unto such as keep his covenant and his testimonies.")
  }

  func testSundayChapterForTerce() {
    let chapter = dataset.office(.terce)!.chapters["0"]!
    XCTAssertEqual(chapter.reference, "1 John 4:16")
  }

  // MARK: - Failure handling

  func testMalformedJSONDecodesToAnEmptyDatasetRatherThanCrashing() {
    let empty = LittleHoursDataset.decode(from: Data("{ not json".utf8))
    XCTAssertTrue(empty.offices.isEmpty)
    XCTAssertEqual(empty.gloria, "")
  }
}
