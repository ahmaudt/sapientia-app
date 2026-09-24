import XCTest

@testable import sapientia

/// Task 1 - reminder preferences for the three notice-only offices.
///
/// Mirrors `LittleHoursSettingsTests`, with the two defaults that deliberately
/// differ: Sundays remind here, and there is no `remindsDuringSession` twin -
/// that promise is kept by `TimersUtil.preservedPrefixes`, not by a flag.
final class DailyOfficeSettingsTests: XCTestCase {

  override func setUp() {
    super.setUp()
    DailyOfficeSettings.reset()
  }

  override func tearDown() {
    DailyOfficeSettings.reset()
    super.tearDown()
  }

  // MARK: - Defaults

  func testDefaultTimesFollowTheCommunityTheAppSourcesFrom() {
    // prayer.covert.org publishes Morning Prayer at 8:45 and Evening Prayer
    // at 5:30. Compline has no canonical hour in any source - 21:00 is a
    // stated convention.
    XCTAssertEqual(DailyOfficeSettings.minutes(for: .matins), 8 * 60 + 45)
    XCTAssertEqual(DailyOfficeSettings.minutes(for: .evensong), 17 * 60 + 30)
    XCTAssertEqual(DailyOfficeSettings.minutes(for: .compline), 21 * 60)
  }

  func testAllThreeOfficesRemindByDefault() {
    for office in DailyOffice.allCases {
      XCTAssertTrue(DailyOfficeSettings.isEnabled(office), "\(office.rawValue) should default on")
    }
  }

  /// The inverse of the Little Hours' default, and the whole point of the
  /// separate switch: Sunday is when the parish call matters most.
  func testSundaysRemindByDefaultUnlikeTheLittleHours() {
    XCTAssertTrue(DailyOfficeSettings.remindsOnSundays)
    XCTAssertFalse(LittleHoursSettings.remindsOnSundays)
  }

  func testEachOfficeNamesItselfBarely() {
    XCTAssertEqual(DailyOffice.matins.displayName, "Matins")
    XCTAssertEqual(DailyOffice.evensong.displayName, "Evensong")
    XCTAssertEqual(DailyOffice.compline.displayName, "Compline")
  }

  // MARK: - Round trips

  func testSettingATimePersists() {
    DailyOfficeSettings.setMinutes(6 * 60 + 15, for: .matins)
    XCTAssertEqual(DailyOfficeSettings.minutes(for: .matins), 6 * 60 + 15)
    // The others are untouched.
    XCTAssertEqual(DailyOfficeSettings.minutes(for: .evensong), 17 * 60 + 30)
  }

  /// `integer(forKey:)` returns 0 for an absent key, which is
  /// indistinguishable from a user who set the office to midnight. This test
  /// fails if the implementation reads that way instead of `object(forKey:)`.
  func testMidnightIsStoredAsMidnightNotAsAnAbsentKey() {
    DailyOfficeSettings.setMinutes(0, for: .compline)
    XCTAssertEqual(DailyOfficeSettings.minutes(for: .compline), 0)
  }

  func testDisablingAnOfficePersistsAndLeavesTheOthersOn() {
    DailyOfficeSettings.setEnabled(false, for: .evensong)
    XCTAssertFalse(DailyOfficeSettings.isEnabled(.evensong))
    XCTAssertTrue(DailyOfficeSettings.isEnabled(.matins))
    XCTAssertTrue(DailyOfficeSettings.isEnabled(.compline))
  }

  func testSundayPreferencePersists() {
    DailyOfficeSettings.remindsOnSundays = false
    XCTAssertFalse(DailyOfficeSettings.remindsOnSundays)
  }

  /// The two sets must not alias each other's storage keys.
  func testTheTwoSetsKeepSeparateStorage() {
    DailyOfficeSettings.remindsOnSundays = false
    LittleHoursSettings.remindsOnSundays = true

    XCTAssertFalse(DailyOfficeSettings.remindsOnSundays)
    XCTAssertTrue(LittleHoursSettings.remindsOnSundays)

    LittleHoursSettings.reset()
  }

  func testResetRestoresEveryDefault() {
    DailyOfficeSettings.setMinutes(1, for: .matins)
    DailyOfficeSettings.setEnabled(false, for: .compline)
    DailyOfficeSettings.remindsOnSundays = false

    DailyOfficeSettings.reset()

    XCTAssertEqual(DailyOfficeSettings.minutes(for: .matins), 8 * 60 + 45)
    XCTAssertTrue(DailyOfficeSettings.isEnabled(.compline))
    XCTAssertTrue(DailyOfficeSettings.remindsOnSundays)
  }
}
