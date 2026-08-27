import UserNotifications
import XCTest

@testable import sapientia

/// This file declares its own double on purpose. `NotificationCenterMock` in
/// `FeastNotificationTests.swift` is `private`, which in Swift is *file*
/// scope, not target scope — referencing it from here would not compile.
private final class OfficeCenterMock: UserNotificationCentering {
  var pending: [String] = []
  var added: [UNNotificationRequest] = []
  var removed: [String] = []

  func pendingRequestIdentifiers(completion: @escaping ([String]) -> Void) {
    completion(pending)
  }

  func removePendingRequests(withIdentifiers identifiers: [String]) {
    removed.append(contentsOf: identifiers)
    pending.removeAll { identifiers.contains($0) }
  }

  func add(_ request: UNNotificationRequest) {
    added.append(request)
    pending.append(request.identifier)
  }

  func requestAuthorization(completion: @escaping (Bool) -> Void) {
    completion(true)
  }

  var triggers: [UNCalendarNotificationTrigger] {
    added.compactMap { $0.trigger as? UNCalendarNotificationTrigger }
  }

  func identifiers(containing fragment: String) -> [String] {
    added.map(\.identifier).filter { $0.contains(fragment) }
  }
}

/// Task 5 — the three daily notices.
final class OfficeNotificationTests: XCTestCase {

  private var calendar: Calendar!
  private var store: KeptHoursStore!

  /// 2026-08-24 is a Monday, so a 10-day window from here spans exactly one
  /// Sunday — the arithmetic below depends on that.
  private func monday() -> Date { date(2026, 8, 24) }

  private func date(_ year: Int, _ month: Int, _ day: Int, _ hour: Int = 12) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = hour
    return calendar.date(from: components)!
  }

  override func setUp() {
    super.setUp()
    calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Edmonton")!
    store = KeptHoursStore(calendar: calendar)
    store.reset()
    LittleHoursSettings.reset()
  }

  override func tearDown() {
    store.reset()
    LittleHoursSettings.reset()
    store = nil
    calendar = nil
    super.tearDown()
  }

  private func scheduler(_ center: OfficeCenterMock) -> OfficeNotificationScheduler {
    OfficeNotificationScheduler(center: center, calendar: calendar, store: store)
  }

  // MARK: - The window

  func testMondayStartQuietSundaysSchedulesTwentySeven() {
    let center = OfficeCenterMock()
    scheduler(center).reschedule(from: monday())
    // 10 days from a Monday contains 1 Sunday -> 9 days x 3 hours.
    XCTAssertEqual(center.added.count, 27)
  }

  func testEnablingSundaysSchedulesThirty() {
    LittleHoursSettings.remindsOnSundays = true
    let center = OfficeCenterMock()
    scheduler(center).reschedule(from: monday())
    XCTAssertEqual(center.added.count, 30)
  }

  /// iOS keeps at most 64 pending local notifications and silently drops the
  /// rest. The office window has to leave room for the 14 feast notices and
  /// whatever session timers are outstanding.
  func testTheWindowLeavesHeadroomUnderTheSixtyFourCap() {
    LittleHoursSettings.remindsOnSundays = true
    let center = OfficeCenterMock()
    scheduler(center).reschedule(from: monday())

    let feastNotices = FeastNotificationScheduler.windowInDays
    XCTAssertLessThan(center.added.count + feastNotices, 64)
  }

  func testEveryRequestIsACalendarTriggerWithTheOfficePrefix() {
    let center = OfficeCenterMock()
    scheduler(center).reschedule(from: monday())

    for request in center.added {
      XCTAssertTrue(request.identifier.hasPrefix("office-"), request.identifier)
      XCTAssertTrue(request.trigger is UNCalendarNotificationTrigger, request.identifier)
    }
    XCTAssertEqual(center.triggers.count, center.added.count)
  }

  func testReschedulingClearsOnlyItsOwnPreviousNotices() {
    let center = OfficeCenterMock()
    center.pending = ["office-2026-01-01-terce", "feast-2026-01-01", "session-xyz"]

    scheduler(center).reschedule(from: monday())

    XCTAssertTrue(center.removed.contains("office-2026-01-01-terce"))
    XCTAssertFalse(center.removed.contains("feast-2026-01-01"))
    XCTAssertFalse(center.removed.contains("session-xyz"))
  }

  // MARK: - Honouring the settings

  func testDisablingAnHourDropsExactlyThatHour() {
    LittleHoursSettings.setEnabled(false, for: .sext)
    let center = OfficeCenterMock()
    scheduler(center).reschedule(from: monday())

    XCTAssertTrue(center.identifiers(containing: "-sext").isEmpty)
    XCTAssertEqual(center.identifiers(containing: "-terce").count, 9)
    XCTAssertEqual(center.identifiers(containing: "-none").count, 9)
  }

  func testChangingATimeMovesItsTriggers() {
    LittleHoursSettings.setMinutes(13 * 60 + 37, for: .sext)
    let center = OfficeCenterMock()
    scheduler(center).reschedule(from: monday())

    let sextTriggers = center.added
      .filter { $0.identifier.contains("-sext") }
      .compactMap { $0.trigger as? UNCalendarNotificationTrigger }

    XCTAssertFalse(sextTriggers.isEmpty)
    for trigger in sextTriggers {
      XCTAssertEqual(trigger.dateComponents.hour, 13)
      XCTAssertEqual(trigger.dateComponents.minute, 37)
    }
  }

  func testQuietSundaysProduceNoSundayNotices() {
    let center = OfficeCenterMock()
    scheduler(center).reschedule(from: monday())
    // The only Sunday in a 10-day window from Mon 24 Aug is 30 Aug.
    XCTAssertTrue(center.identifiers(containing: "2026-08-30").isEmpty)

    LittleHoursSettings.remindsOnSundays = true
    let withSundays = OfficeCenterMock()
    scheduler(withSundays).reschedule(from: monday())
    XCTAssertEqual(withSundays.identifiers(containing: "2026-08-30").count, 3)
  }

  /// Screen 29: a notice is "dismissed by praying it or by the day ending".
  func testAnHourAlreadyKeptGetsNoNoticeThatDay() {
    store.record(.terce, on: monday(), at: monday())
    let center = OfficeCenterMock()
    scheduler(center).reschedule(from: monday())

    XCTAssertTrue(center.identifiers(containing: "2026-08-24-terce").isEmpty)
    // Only that day's Terce is suppressed; the rest stand.
    XCTAssertEqual(center.identifiers(containing: "2026-08-25-terce").count, 1)
    XCTAssertEqual(center.identifiers(containing: "2026-08-24-sext").count, 1)
  }

  // MARK: - Content

  func testNoticeMatchesTheDesignsPreviewCard() {
    let center = OfficeCenterMock()
    scheduler(center).reschedule(from: monday())

    let sext = center.added.first { $0.identifier == "office-2026-08-24-sext" }
    XCTAssertEqual(sext?.content.title, "Midday — Sext")
    XCTAssertEqual(sext?.content.body, "The sixth hour. Psalms 123, 124, 125.")
  }

  func testEachHourNamesItselfAndItsPsalms() {
    let center = OfficeCenterMock()
    scheduler(center).reschedule(from: monday())

    let terce = center.added.first { $0.identifier == "office-2026-08-24-terce" }
    XCTAssertEqual(terce?.content.title, "Midmorning — Terce")
    XCTAssertEqual(terce?.content.body, "The third hour. Psalms 120, 121, 122.")

    let none = center.added.first { $0.identifier == "office-2026-08-24-none" }
    XCTAssertEqual(none?.content.title, "Midafternoon — None")
    XCTAssertEqual(none?.content.body, "The ninth hour. Psalms 126, 127, 128.")
  }
}
