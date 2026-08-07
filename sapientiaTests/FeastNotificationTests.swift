import UserNotifications
import XCTest

@testable import sapientia

private final class NotificationCenterMock: UserNotificationCentering {
  var pending: [String] = []
  var added: [UNNotificationRequest] = []
  var removed: [String] = []
  var removedAll = false

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

final class FeastNotificationSchedulerTests: XCTestCase {

  override func tearDown() {
    PrayerSettings.reset()
    super.tearDown()
  }

  private func date(_ year: Int, _ month: Int, _ day: Int) -> Date {
    var components = DateComponents()
    components.year = year
    components.month = month
    components.day = day
    components.hour = 12
    return Calendar(identifier: .gregorian).date(from: components)!
  }

  func testSchedulesFourteenSixOClockNotices() {
    PrayerSettings.feastNoticeEnabled = true
    let center = NotificationCenterMock()
    let scheduler = FeastNotificationScheduler(center: center)

    scheduler.reschedule(from: date(2026, 8, 1))

    XCTAssertEqual(center.added.count, 14)
    for request in center.added {
      XCTAssertTrue(request.identifier.hasPrefix("feast-"), request.identifier)
      let trigger = request.trigger as? UNCalendarNotificationTrigger
      XCTAssertEqual(trigger?.dateComponents.hour, 6)
      XCTAssertEqual(trigger?.dateComponents.minute, 0)
    }
    // Aug 6 2026 is the Transfiguration — its notice must carry the feast.
    let transfiguration = center.added.first { $0.identifier == "feast-2026-08-06" }
    XCTAssertEqual(
      transfiguration?.content.title, "The Transfiguration of Our Lord")
    // Aug 7 carries the commemoration in the body.
    let sixtus = center.added.first { $0.identifier == "feast-2026-08-07" }
    XCTAssertEqual(sixtus?.content.title, "Friday after Trinity IX")
    XCTAssertTrue(
      sixtus?.content.body.contains("S. Sixtus II") == true,
      sixtus?.content.body ?? "nil")
  }

  func testRescheduleReplacesPreviousFeastNotices() {
    PrayerSettings.feastNoticeEnabled = true
    let center = NotificationCenterMock()
    center.pending = ["feast-2026-07-01", "other-notification"]
    let scheduler = FeastNotificationScheduler(center: center)

    scheduler.reschedule(from: date(2026, 8, 1))

    XCTAssertTrue(center.removed.contains("feast-2026-07-01"))
    XCTAssertFalse(center.removed.contains("other-notification"))
  }

  func testDisabledCancelsAllFeastNotices() {
    PrayerSettings.feastNoticeEnabled = false
    let center = NotificationCenterMock()
    center.pending = ["feast-2026-08-06", "session-reminder"]
    let scheduler = FeastNotificationScheduler(center: center)

    scheduler.reschedule(from: date(2026, 8, 1))

    XCTAssertEqual(center.added.count, 0)
    XCTAssertTrue(center.removed.contains("feast-2026-08-06"))
    XCTAssertFalse(center.removed.contains("session-reminder"))
  }
}

final class TimersUtilNotificationScopeTests: XCTestCase {

  func testCancelAllNotificationsSparesFeastNotices() {
    let center = NotificationCenterMock()
    center.pending = ["feast-2026-08-06", "feast-2026-08-07", "reminder-abc", "xyz"]

    TimersUtil.cancelNonFeastNotifications(center: center)

    XCTAssertTrue(center.removed.contains("reminder-abc"))
    XCTAssertTrue(center.removed.contains("xyz"))
    XCTAssertFalse(center.removed.contains("feast-2026-08-06"))
    XCTAssertFalse(center.removed.contains("feast-2026-08-07"))
  }
}
