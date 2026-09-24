import UserNotifications
import XCTest

@testable import sapientia

/// This file declares its own double on purpose. The mocks in
/// `OfficeNotificationTests.swift` and `FeastNotificationTests.swift` are
/// `private`, which in Swift is *file* scope, not target scope - referencing
/// either from here would not compile. One double per file is the existing
/// convention.
private final class DailyOfficeCenterMock: UserNotificationCentering {
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

  func identifiers(containing fragment: String) -> [String] {
    added.map(\.identifier).filter { $0.contains(fragment) }
  }

  func request(withIdentifier identifier: String) -> UNNotificationRequest? {
    added.first { $0.identifier == identifier }
  }
}

/// Task 2 - the notices for Matins, Evensong and Compline.
final class DailyOfficeNotificationTests: XCTestCase {

  private var calendar: Calendar!

  /// 2026-08-24 is a Monday. A 9-day window from here runs to 1 September and
  /// spans exactly one Sunday, the 30th.
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
    DailyOfficeSettings.reset()
  }

  override func tearDown() {
    DailyOfficeSettings.reset()
    calendar = nil
    super.tearDown()
  }

  private func scheduler(_ center: DailyOfficeCenterMock) -> DailyOfficeNotificationScheduler {
    DailyOfficeNotificationScheduler(center: center, calendar: calendar)
  }

  // MARK: - The window

  /// Sundays remind by default here, so the full nine days carry notices.
  func testDefaultsScheduleTwentySevenAcrossNineDays() {
    let center = DailyOfficeCenterMock()
    scheduler(center).reschedule(from: monday())
    XCTAssertEqual(center.added.count, 27)
  }

  func testQuietSundaysDropExactlyThatDay() {
    DailyOfficeSettings.remindsOnSundays = false
    let center = DailyOfficeCenterMock()
    scheduler(center).reschedule(from: monday())

    XCTAssertEqual(center.added.count, 24)
    XCTAssertTrue(center.identifiers(containing: "2026-08-30").isEmpty)
  }

  func testEveryRequestIsACalendarTriggerWithTheDailyPrefix() {
    let center = DailyOfficeCenterMock()
    scheduler(center).reschedule(from: monday())

    for request in center.added {
      XCTAssertTrue(request.identifier.hasPrefix("daily-"), request.identifier)
      XCTAssertTrue(request.trigger is UNCalendarNotificationTrigger, request.identifier)
    }
  }

  func testDisablingAnOfficeDropsExactlyThatOffice() {
    DailyOfficeSettings.setEnabled(false, for: .evensong)
    let center = DailyOfficeCenterMock()
    scheduler(center).reschedule(from: monday())

    XCTAssertEqual(center.added.count, 18)
    XCTAssertTrue(center.identifiers(containing: "-evensong").isEmpty)
    XCTAssertEqual(center.identifiers(containing: "-matins").count, 9)
    XCTAssertEqual(center.identifiers(containing: "-compline").count, 9)
  }

  func testChangingATimeMovesItsTriggers() {
    DailyOfficeSettings.setMinutes(6 * 60 + 5, for: .compline)
    let center = DailyOfficeCenterMock()
    scheduler(center).reschedule(from: monday())

    let compline = center.added
      .filter { $0.identifier.contains("-compline") }
      .compactMap { $0.trigger as? UNCalendarNotificationTrigger }
    XCTAssertEqual(compline.count, 9)
    for trigger in compline {
      XCTAssertEqual(trigger.dateComponents.hour, 6)
      XCTAssertEqual(trigger.dateComponents.minute, 5)
    }
  }

  /// The default hours, as minute components on the real triggers.
  func testEachOfficeFiresAtItsDefaultHour() {
    let center = DailyOfficeCenterMock()
    scheduler(center).reschedule(from: monday())

    let expected: [DailyOffice: (Int, Int)] = [
      .matins: (8, 45),
      .evensong: (17, 30),
      .compline: (21, 0),
    ]
    for (office, time) in expected {
      let trigger = center.request(withIdentifier: "daily-2026-08-24-\(office.rawValue)")?
        .trigger as? UNCalendarNotificationTrigger
      XCTAssertEqual(trigger?.dateComponents.hour, time.0, office.rawValue)
      XCTAssertEqual(trigger?.dateComponents.minute, time.1, office.rawValue)
    }
  }

  // MARK: - What the notice says

  /// 2026-11-15 is Trinity XXIV per `OrdinariateCalendarTests`. The title is
  /// the bare office name and the body is the day - not the psalms, which
  /// these offices do not ship.
  func testANoticeNamesTheOfficeAndTheDay() {
    let center = DailyOfficeCenterMock()
    scheduler(center).reschedule(from: date(2026, 11, 15))

    let request = center.request(withIdentifier: "daily-2026-11-15-evensong")
    XCTAssertEqual(request?.content.title, "Evensong")
    XCTAssertEqual(request?.content.body, "Trinity XXIV.")
  }

  /// The body has to follow the day, not the office - that is the whole
  /// reason these cannot be one repeating trigger apiece. Trinity XXIV and
  /// Christ the King are seven days apart, so both land in one window.
  func testTheBodyFollowsTheDayNotTheOffice() {
    let center = DailyOfficeCenterMock()
    scheduler(center).reschedule(from: date(2026, 11, 15))

    XCTAssertEqual(
      center.request(withIdentifier: "daily-2026-11-15-matins")?.content.body,
      "Trinity XXIV.")
    XCTAssertEqual(
      center.request(withIdentifier: "daily-2026-11-22-matins")?.content.body,
      "Christ the King.")
  }

  func testEveryOfficeOnADayCarriesTheSameDayButItsOwnName() {
    let center = DailyOfficeCenterMock()
    scheduler(center).reschedule(from: date(2026, 12, 25))

    for office in DailyOffice.allCases {
      let request = center.request(withIdentifier: "daily-2026-12-25-\(office.rawValue)")
      XCTAssertEqual(request?.content.title, office.displayName)
      XCTAssertEqual(request?.content.body, "Christmas Day.")
    }
  }

  // MARK: - Clearing

  func testReschedulingClearsOnlyItsOwnPreviousNotices() {
    let center = DailyOfficeCenterMock()
    center.pending = [
      "daily-2026-08-20-matins",
      "office-2026-08-20-terce",
      "feast-2026-08-20",
      "1D9F0C4E-STALE-SESSION-TIMER",
    ]

    scheduler(center).reschedule(from: monday())

    XCTAssertEqual(center.removed, ["daily-2026-08-20-matins"])
    XCTAssertTrue(center.pending.contains("office-2026-08-20-terce"))
    XCTAssertTrue(center.pending.contains("feast-2026-08-20"))
    XCTAssertTrue(center.pending.contains("1D9F0C4E-STALE-SESSION-TIMER"))
  }
}
