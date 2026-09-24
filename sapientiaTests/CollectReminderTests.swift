import UserNotifications
import XCTest

@testable import sapientia

private final class NotificationCenterMock: UserNotificationCentering {
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
}

final class CollectReminderSchedulerTests: XCTestCase {

  override func setUp() {
    super.setUp()
    CollectReminderSettings.reset()
    PrayerSettings.reset()
  }

  override func tearDown() {
    CollectReminderSettings.reset()
    PrayerSettings.reset()
    super.tearDown()
  }

  /// Local noon, the way the scheduler reads the day.
  private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
    Calendar.current.date(
      from: DateComponents(year: year, month: month, day: day, hour: hour))!
  }

  private func reschedule(
    from start: Date, center: NotificationCenterMock = NotificationCenterMock()
  )
    -> NotificationCenterMock
  {
    CollectReminderScheduler(center: center).reschedule(from: start)
    return center
  }

  private func request(_ id: String, in center: NotificationCenterMock) -> UNNotificationRequest? {
    center.added.first { $0.identifier == id }
  }

  // MARK: - The morning notice

  func testGivenTheDefaults_WhenRescheduledAtNoon_ThenFourteenSixOClockNoticesStartTomorrow() {
    CollectReminderSettings.isEnabled = true
    let center = reschedule(from: date(2026, 8, 7))

    XCTAssertEqual(center.added.count, 14)
    XCTAssertEqual(center.added.first?.identifier, "collect-2026-08-08-0600")
    XCTAssertEqual(center.added.last?.identifier, "collect-2026-08-21-0600")
    for request in center.added {
      let trigger = request.trigger as? UNCalendarNotificationTrigger
      XCTAssertEqual(trigger?.dateComponents.hour, 6)
      XCTAssertEqual(trigger?.dateComponents.minute, 0)
      XCTAssertEqual(trigger?.repeats, false)
    }
  }

  func
    testGivenAWeekdayMemorial_WhenItsMorningNoticeIsBuilt_ThenItNamesTheMemorialAndCarriesItsCollect()
  {
    CollectReminderSettings.isEnabled = true
    let center = reschedule(from: date(2026, 8, 7))

    let dominic = request("collect-2026-08-08-0600", in: center)
    XCTAssertEqual(dominic?.content.title, "Today: The memorial of S. Dominic, Priest")
    // The same collect the home card and the shield show that day.
    XCTAssertEqual(
      dominic?.content.body, OrdinariateCalendar().day(for: date(2026, 8, 8)).collect.text)

    let sunday = request("collect-2026-08-09-0600", in: center)
    XCTAssertEqual(sunday?.content.title, "Today: Trinity X")
  }

  // MARK: - The evening before

  func testGivenTheEveningBefore_WhenTomorrowKeepsASaint_ThenTonightAnnouncesIt() {
    CollectReminderSettings.isEnabled = true
    CollectReminderSettings.whichDays = .saintsAndFeasts
    CollectReminderSettings.eveningBeforeEnabled = true
    let center = reschedule(from: date(2026, 8, 7))

    let eve = request("collect-2026-08-07-eve", in: center)
    XCTAssertEqual(eve?.content.title, "Tomorrow is the memorial of S. Dominic, Priest.")
    XCTAssertEqual(eve?.content.body, "")
    let trigger = eve?.trigger as? UNCalendarNotificationTrigger
    XCTAssertEqual(trigger?.dateComponents.day, 7)
    XCTAssertEqual(trigger?.dateComponents.hour, 20)
    XCTAssertEqual(center.added.first?.identifier, "collect-2026-08-07-eve")

    // Sunday 9 August keeps no saint: nothing is announced on the Saturday.
    XCTAssertNil(request("collect-2026-08-08-eve", in: center))
    XCTAssertNil(request("collect-2026-08-09-0600", in: center))
  }

  // MARK: - Which days

  func testGivenFeastsOnly_WhenRescheduled_ThenMemorialsAreSkippedAndFeastsNamed() {
    CollectReminderSettings.isEnabled = true
    CollectReminderSettings.whichDays = .feastsOnly
    let center = reschedule(from: date(2026, 8, 7))

    XCTAssertNil(request("collect-2026-08-08-0600", in: center))
    XCTAssertEqual(
      request("collect-2026-08-10-0600", in: center)?.content.title,
      "Today: The Feast of S. Lawrence, Deacon & Martyr")
  }

  func testGivenTheHeaviestSettings_WhenRescheduled_ThenThePendingBudgetHolds() {
    CollectReminderSettings.isEnabled = true
    CollectReminderSettings.times = [360, 720, 1080]
    CollectReminderSettings.eveningBeforeEnabled = true
    let center = reschedule(from: date(2026, 8, 7, hour: 1))

    XCTAssertEqual(center.added.count, CollectReminderScheduler.requestBudget)
    XCTAssertEqual(CollectReminderScheduler.requestBudget, 14)
    // Filled in time order, so the nearest notices are never the ones dropped.
    let fireDates = center.added.compactMap {
      ($0.trigger as? UNCalendarNotificationTrigger)?.nextTriggerDate()
    }
    XCTAssertEqual(fireDates, fireDates.sorted())
    XCTAssertEqual(center.added.first?.identifier, "collect-2026-08-07-0600")
  }

  // MARK: - Migration and switching off

  func testGivenOnlyTheOldFeastNotice_WhenUpgraded_ThenTheReminderIsOnAndOldNoticesAreReplaced() {
    UserDefaults(suiteName: "group.com.artempleton.sapientia")!
      .set(true, forKey: "sapientiaFeastNoticeEnabled")
    XCTAssertTrue(CollectReminderSettings.isEnabled)

    let center = NotificationCenterMock()
    center.pending = ["feast-2026-08-06", "reminder-abc"]
    _ = reschedule(from: date(2026, 8, 7), center: center)

    XCTAssertTrue(center.removed.contains("feast-2026-08-06"))
    XCTAssertFalse(center.removed.contains("reminder-abc"))
    XCTAssertEqual(center.added.first?.identifier, "collect-2026-08-08-0600")
  }

  func testGivenTheReminderOff_WhenRescheduled_ThenEveryCollectAndFeastNoticeIsRemoved() {
    CollectReminderSettings.isEnabled = false
    let center = NotificationCenterMock()
    center.pending = ["collect-2026-08-08-0600", "feast-2026-08-06", "session-reminder"]
    _ = reschedule(from: date(2026, 8, 7), center: center)

    XCTAssertTrue(center.added.isEmpty)
    XCTAssertTrue(center.removed.contains("collect-2026-08-08-0600"))
    XCTAssertTrue(center.removed.contains("feast-2026-08-06"))
    XCTAssertFalse(center.removed.contains("session-reminder"))
  }

  // MARK: - Settings

  func testTimesAreUniqueAscendingAndAtMostThree() {
    // The first three distinct times given are kept, then sorted.
    CollectReminderSettings.times = [1080, 360, 360, 720, 900]
    XCTAssertEqual(CollectReminderSettings.times, [360, 720, 1080])
    CollectReminderSettings.times = []
    XCTAssertEqual(CollectReminderSettings.times, [360])
  }

  func testDefaultsMatchTheNoticeTheyReplace() {
    XCTAssertFalse(CollectReminderSettings.isEnabled)
    XCTAssertEqual(CollectReminderSettings.whichDays, .everyDay)
    XCTAssertEqual(CollectReminderSettings.times, [360])
    XCTAssertFalse(CollectReminderSettings.eveningBeforeEnabled)
    XCTAssertEqual(CollectReminderSettings.eveningBeforeMinutes, 1200)
  }
}

final class TimersUtilNotificationScopeTests: XCTestCase {

  func testCancelAllNotificationsSparesCollectReminders() {
    let center = NotificationCenterMock()
    center.pending = ["collect-2026-08-06-0600", "collect-2026-08-06-eve", "reminder-abc", "xyz"]

    TimersUtil.cancelNonSessionNotifications(center: center)

    XCTAssertTrue(center.removed.contains("reminder-abc"))
    XCTAssertTrue(center.removed.contains("xyz"))
    XCTAssertFalse(center.removed.contains("collect-2026-08-06-0600"))
    XCTAssertFalse(center.removed.contains("collect-2026-08-06-eve"))
  }

  /// Screen 29 promises the office is never blocked: "The notice still comes."
  /// Session cleanup runs on every start and stop, so without this the day's
  /// remaining hours would be silently deleted the moment a rule began.
  func testCancelAllNotificationsSparesOfficeNotices() {
    let center = NotificationCenterMock()
    center.pending = [
      "office-2026-08-27-terce", "office-2026-08-27-sext",
      "collect-2026-08-27-0600", "reminder-abc",
    ]

    TimersUtil.cancelNonSessionNotifications(center: center)

    XCTAssertFalse(center.removed.contains("office-2026-08-27-terce"))
    XCTAssertFalse(center.removed.contains("office-2026-08-27-sext"))
    XCTAssertFalse(center.removed.contains("collect-2026-08-27-0600"))
    XCTAssertTrue(center.removed.contains("reminder-abc"))
  }
}
