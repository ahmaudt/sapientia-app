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

  /// 2026-08-24 is a Monday. A 5-day window from here is Mon-Fri and spans
  /// **no** Sunday at all, so tests about Sunday conduct cannot start here.
  private func monday() -> Date { date(2026, 8, 24) }

  /// 2026-08-27 is a Thursday, so a 5-day window from here is Thu-Mon and
  /// spans exactly one Sunday, 30 August. Every count that depends on the
  /// Sunday skip starts here instead.
  private func thursday() -> Date { date(2026, 8, 27) }

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

  func testThursdayStartQuietSundaysSchedulesTwelve() {
    let center = OfficeCenterMock()
    scheduler(center).reschedule(from: thursday())
    // 5 days from a Thursday contains 1 Sunday -> 4 days x 3 hours.
    XCTAssertEqual(center.added.count, 12)
  }

  func testEnablingSundaysSchedulesFifteen() {
    LittleHoursSettings.remindsOnSundays = true
    let center = OfficeCenterMock()
    scheduler(center).reschedule(from: thursday())
    XCTAssertEqual(center.added.count, 15)
  }

  /// iOS keeps at most 64 pending local notifications and silently drops the
  /// rest. All three schedulers share that one budget, so the assertion has
  /// to span all three rather than the Little Hours alone - the Little Hours
  /// window could shrink to nothing and the app would still overflow if the
  /// other two grew.
  ///
  /// Derived from the schedulers' own constants rather than literals, so
  /// changing any window or budget moves this assertion with it instead of
  /// leaving a stale number that passes by accident. The collect reminder is
  /// capped by a request budget rather than a window, since its requests per
  /// day vary with its settings.
  func testTheThreeSchedulersTogetherLeaveHeadroomUnderTheSixtyFourCap() {
    let littleHours = OfficeNotificationScheduler.windowInDays * LittleHour.allCases.count
    let dailyOffice = DailyOfficeNotificationScheduler.windowInDays * DailyOffice.allCases.count
    let collect = CollectReminderScheduler.requestBudget
    let worstCase = littleHours + dailyOffice + collect

    XCTAssertEqual(worstCase, 56)
    // At least 8 slots left for TimersUtil's session notices.
    XCTAssertLessThanOrEqual(worstCase, OfficeNotificationScheduler.systemPendingLimit - 8)
  }

  /// The worst case above is only real if each scheduler actually schedules
  /// its window x its offices. This pins the Little Hours half of it against
  /// live behaviour rather than arithmetic.
  func testTheLittleHoursWorstCaseMatchesItsShareOfTheBudget() {
    LittleHoursSettings.remindsOnSundays = true
    let center = OfficeCenterMock()
    // A Monday start has no Sunday to skip, so this is the true maximum.
    scheduler(center).reschedule(from: monday())

    XCTAssertEqual(
      center.added.count,
      OfficeNotificationScheduler.windowInDays * LittleHour.allCases.count)
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
    // 5 days from a Monday, no Sunday to skip.
    XCTAssertEqual(center.identifiers(containing: "-terce").count, 5)
    XCTAssertEqual(center.identifiers(containing: "-none").count, 5)
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
    scheduler(center).reschedule(from: thursday())
    // The only Sunday in a 5-day window from Thu 27 Aug is 30 Aug.
    XCTAssertTrue(center.identifiers(containing: "2026-08-30").isEmpty)

    LittleHoursSettings.remindsOnSundays = true
    let withSundays = OfficeCenterMock()
    scheduler(withSundays).reschedule(from: thursday())
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
