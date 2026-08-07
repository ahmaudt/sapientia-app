import XCTest

@testable import sapientia

final class RuleRowMetaTests: XCTestCase {

  func testStrictNFCProfile() {
    let meta = RuleRowMeta.metaString(
      appCount: 14, categoryCount: 0, strategyId: "NFCBlockingStrategy",
      isStrict: true, scheduleText: nil)
    XCTAssertEqual(meta, "14 apps · NFC tag · strict")
  }

  func testScheduledQRProfile() {
    let meta = RuleRowMeta.metaString(
      appCount: 22, categoryCount: 0, strategyId: "QRCodeBlockingStrategy",
      isStrict: false, scheduleText: "21:00–06:00")
    XCTAssertEqual(meta, "22 apps · QR code · 21:00–06:00")
  }

  func testDefaultNFCTail() {
    let meta = RuleRowMeta.metaString(
      appCount: 31, categoryCount: 0, strategyId: "NFCManualBlockingStrategy",
      isStrict: false, scheduleText: nil)
    XCTAssertEqual(meta, "31 apps · NFC tag · until tapped out")
  }

  func testCategoriesIncluded() {
    let meta = RuleRowMeta.metaString(
      appCount: 14, categoryCount: 3, strategyId: "NFCBlockingStrategy",
      isStrict: false, scheduleText: nil)
    XCTAssertTrue(meta.hasPrefix("14 apps · 3 categories"), meta)
  }

  func testTimerAndManualStrategies() {
    XCTAssertEqual(
      RuleRowMeta.metaString(
        appCount: 5, categoryCount: 0, strategyId: "ShortcutTimerBlockingStrategy",
        isStrict: false, scheduleText: nil),
      "5 apps · timer · until timer ends")
    XCTAssertEqual(
      RuleRowMeta.metaString(
        appCount: 5, categoryCount: 0, strategyId: "ManualBlockingStrategy",
        isStrict: false, scheduleText: nil),
      "5 apps · manual · until stopped")
  }

  func testSingularCounts() {
    let meta = RuleRowMeta.metaString(
      appCount: 1, categoryCount: 1, strategyId: "QRTimerBlockingStrategy",
      isStrict: false, scheduleText: nil)
    XCTAssertTrue(meta.hasPrefix("1 app · 1 category"), meta)
  }
}

final class WeeklyKeptTimeTests: XCTestCase {

  func testHoursAndMinutes() {
    XCTAssertEqual(HomeStats.keptTimeString(12 * 3600 + 40 * 60), "12h 40m")
  }

  func testMinutesOnly() {
    XCTAssertEqual(HomeStats.keptTimeString(45 * 60), "45m")
  }

  func testWholeHours() {
    XCTAssertEqual(HomeStats.keptTimeString(2 * 3600), "2h")
  }

  func testZero() {
    XCTAssertEqual(HomeStats.keptTimeString(0), "0m")
  }

  func testSubMinuteRoundsDown() {
    XCTAssertEqual(HomeStats.keptTimeString(59), "0m")
  }
}
