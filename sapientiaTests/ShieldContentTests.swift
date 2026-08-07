import Foundation
import XCTest

@testable import sapientia

final class ShieldContentTests: XCTestCase {

  private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = 12
    return Calendar(identifier: .gregorian).date(from: components)!
  }

  override func tearDown() {
    PrayerSettings.reset()
    super.tearDown()
  }

  // MARK: - PrayerSettings

  func testDefaultPrayerIsBenedict() {
    PrayerSettings.reset()
    XCTAssertEqual(PrayerSettings.blockScreenPrayer, .benedict)
  }

  func testPrayerSettingRoundTrips() {
    PrayerSettings.blockScreenPrayer = .collect
    XCTAssertEqual(PrayerSettings.blockScreenPrayer, .collect)
    PrayerSettings.blockScreenPrayer = .benedict
    XCTAssertEqual(PrayerSettings.blockScreenPrayer, .benedict)
  }

  func testCalendarChoiceDefaultsToOrdinariate() {
    PrayerSettings.reset()
    XCTAssertEqual(PrayerSettings.calendarChoice, .ordinariate)
  }

  // MARK: - Prayer shield content

  func testBenedictShield() {
    let shield = ShieldContent.prayerShield(
      prayer: .benedict,
      date: date(2026, 8, 7),
      blockedItemName: "Instagram",
      unblockPhrase: "until you tap your tag"
    )
    XCTAssertEqual(shield.title, "Prayer of St. Benedict")
    XCTAssertTrue(shield.subtitle.contains("O GRACIOUS and holy Father"))
    XCTAssertTrue(shield.subtitle.contains("Instagram is set aside until you tap your tag."))
    XCTAssertEqual(shield.buttonText, "Amen")
  }

  func testCollectShieldUsesLiturgicalDay() {
    let shield = ShieldContent.prayerShield(
      prayer: .collect,
      date: date(2026, 8, 7),
      blockedItemName: "Instagram",
      unblockPhrase: "until you tap your tag"
    )
    XCTAssertEqual(shield.title, "Collect — Friday after Trinity IX")
    XCTAssertTrue(
      shield.subtitle.contains("Grant to us, Lord, we beseech thee"),
      "Expected the Trinity IX collect, got: \(shield.subtitle.prefix(80))")
    XCTAssertEqual(shield.buttonText, "Amen")
  }

  func testCollectShieldFallsBackToBenedictOnMissingData() {
    let empty = OrdinariateCalendar(
      dataset: LiturgicalDataset(sanctorale: [], temporale: [:]))
    let shield = ShieldContent.prayerShield(
      prayer: .collect,
      date: date(2026, 8, 7),
      blockedItemName: "Instagram",
      unblockPhrase: "until you tap your tag",
      calendar: empty
    )
    XCTAssertEqual(shield.title, "Prayer of St. Benedict")
    XCTAssertTrue(shield.subtitle.contains("O GRACIOUS and holy Father"))
  }

  // MARK: - Soft-unblock copy

  func testSoftUnblockAllowanceIndicator() {
    XCTAssertEqual(
      ShieldContent.allowanceIndicator(remaining: 2, maximum: 3), "●  ●  ○")
    XCTAssertEqual(
      ShieldContent.allowanceIndicator(remaining: 0, maximum: 2), "○  ○")
  }

  func testSoftUnblockAvailableCopy() {
    let copy = ShieldContent.softUnblockShield(
      resourceName: "Instagram",
      remaining: 2,
      maximum: 3,
      accessMinutes: 10,
      resetDescription: "Resets in 2h"
    )
    XCTAssertEqual(copy.buttonText, "Open for 10m")
    XCTAssertTrue(copy.subtitle.contains("Instagram (2/3)"))
    XCTAssertTrue(copy.subtitle.contains("●  ●  ○"))
    XCTAssertTrue(copy.subtitle.contains("Resets in 2h"))
  }

  func testSoftUnblockExhaustedCopy() {
    let single = ShieldContent.softUnblockExhausted(
      maximum: 1, resetDescription: nil)
    XCTAssertEqual(single.title, "No opens left")
    XCTAssertTrue(
      single.subtitle.contains("You already used your open for this session."))

    let multiple = ShieldContent.softUnblockExhausted(
      maximum: 3, resetDescription: "Resets in 45m")
    XCTAssertTrue(
      multiple.subtitle.contains("You used all 3 opens for this session."))
    XCTAssertTrue(multiple.subtitle.contains("Resets in 45m"))
  }
}
