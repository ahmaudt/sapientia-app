import XCTest

@testable import sapientia

/// Task 3 — reminder preferences for the Little Hours.
final class LittleHoursSettingsTests: XCTestCase {

  override func setUp() {
    super.setUp()
    LittleHoursSettings.reset()
  }

  override func tearDown() {
    LittleHoursSettings.reset()
    super.tearDown()
  }

  // MARK: - Defaults

  func testDefaultTimesAreTheTraditionalHours() {
    XCTAssertEqual(LittleHoursSettings.minutes(for: .terce), 9 * 60)
    XCTAssertEqual(LittleHoursSettings.minutes(for: .sext), 12 * 60)
    XCTAssertEqual(LittleHoursSettings.minutes(for: .nones), 15 * 60)
  }

  func testAllThreeHoursRemindByDefault() {
    for hour in LittleHour.allCases {
      XCTAssertTrue(LittleHoursSettings.isEnabled(hour), "\(hour.rawValue) should default on")
    }
  }

  func testSundaysAreQuietByDefaultAndSessionsAreNot() {
    // Screen 29: "Quiet. Matins and Evensong belong to the parish."
    XCTAssertFalse(LittleHoursSettings.remindsOnSundays)
    // Screen 29: "The notice still comes; the office is never blocked."
    XCTAssertTrue(LittleHoursSettings.remindsDuringSession)
  }

  // MARK: - Round trips

  func testTimeRoundTripsAsMinutesFromMidnight() {
    LittleHoursSettings.setMinutes(13 * 60 + 37, for: .sext)
    XCTAssertEqual(LittleHoursSettings.minutes(for: .sext), 817)
    // The others are untouched.
    XCTAssertEqual(LittleHoursSettings.minutes(for: .terce), 540)
    XCTAssertEqual(LittleHoursSettings.minutes(for: .nones), 900)
  }

  func testMidnightRoundTripsRatherThanReadingAsUnset() {
    // 0 is a legitimate time and must not be confused with "no value stored",
    // which is the classic UserDefaults integer trap.
    LittleHoursSettings.setMinutes(0, for: .terce)
    XCTAssertEqual(LittleHoursSettings.minutes(for: .terce), 0)
  }

  func testEnablementRoundTrips() {
    LittleHoursSettings.setEnabled(false, for: .terce)
    XCTAssertFalse(LittleHoursSettings.isEnabled(.terce))
    XCTAssertTrue(LittleHoursSettings.isEnabled(.sext))

    LittleHoursSettings.setEnabled(true, for: .terce)
    XCTAssertTrue(LittleHoursSettings.isEnabled(.terce))
  }

  func testConductSwitchesRoundTrip() {
    LittleHoursSettings.remindsOnSundays = true
    LittleHoursSettings.remindsDuringSession = false
    XCTAssertTrue(LittleHoursSettings.remindsOnSundays)
    XCTAssertFalse(LittleHoursSettings.remindsDuringSession)
  }

  func testResetRestoresEveryDefault() {
    LittleHoursSettings.setMinutes(60, for: .terce)
    LittleHoursSettings.setEnabled(false, for: .sext)
    LittleHoursSettings.remindsOnSundays = true
    LittleHoursSettings.remindsDuringSession = false

    LittleHoursSettings.reset()

    XCTAssertEqual(LittleHoursSettings.minutes(for: .terce), 540)
    XCTAssertTrue(LittleHoursSettings.isEnabled(.sext))
    XCTAssertFalse(LittleHoursSettings.remindsOnSundays)
    XCTAssertTrue(LittleHoursSettings.remindsDuringSession)
  }

  // MARK: - Counts the week grid depends on

  func testEnabledWeekdayCountFollowsTheSundaySwitch() {
    XCTAssertEqual(LittleHoursSettings.enabledWeekdayCount, 6)
    LittleHoursSettings.remindsOnSundays = true
    XCTAssertEqual(LittleHoursSettings.enabledWeekdayCount, 7)
  }

  func testEnabledHourCountFollowsThePerHourSwitches() {
    XCTAssertEqual(LittleHoursSettings.enabledHourCount, 3)
    LittleHoursSettings.setEnabled(false, for: .terce)
    XCTAssertEqual(LittleHoursSettings.enabledHourCount, 2)
    LittleHoursSettings.setEnabled(false, for: .sext)
    LittleHoursSettings.setEnabled(false, for: .nones)
    XCTAssertEqual(LittleHoursSettings.enabledHourCount, 0)
  }

  func testEnabledHoursArePresentedInOrderOfTheirTime() {
    // The Hours screen picks the *earliest* overdue hour, so order matters.
    XCTAssertEqual(LittleHoursSettings.enabledHours, [.terce, .sext, .nones])

    LittleHoursSettings.setMinutes(23 * 60, for: .terce)
    XCTAssertEqual(LittleHoursSettings.enabledHours, [.sext, .nones, .terce])

    LittleHoursSettings.setEnabled(false, for: .sext)
    XCTAssertEqual(LittleHoursSettings.enabledHours, [.nones, .terce])
  }
}
