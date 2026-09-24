import UserNotifications
import XCTest

@testable import sapientia

/// Own double — the one in `FeastNotificationTests.swift` is file-private.
private final class RemindersCenterMock: UserNotificationCentering {
  var pending: [String] = []
  var added: [UNNotificationRequest] = []
  var removed: [String] = []
  var status: UNAuthorizationStatus = .authorized
  var authorizationRequests = 0

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
    authorizationRequests += 1
    completion(status == .authorized)
  }

  func authorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
    completion(status)
  }

  func identifiers(containing fragment: String) -> [String] {
    added.map(\.identifier).filter { $0.contains(fragment) }
  }
}

/// Task 8 — the reminders screen.
final class PrayerRemindersTests: XCTestCase {

  private var calendar: Calendar!
  private var store: KeptHoursStore!
  private var center: RemindersCenterMock!

  /// A Thursday, so the Little Hours' 5-day window holds exactly one Sunday
  /// (30 August). A Monday start would run Mon-Fri and reach no Sunday at
  /// all, which would make the Sunday assertions below vacuous.
  private var thursday: Date {
    var components = DateComponents()
    components.year = 2026
    components.month = 8
    components.day = 27
    components.hour = 12
    return calendar.date(from: components)!
  }

  override func setUp() {
    super.setUp()
    calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(identifier: "America/Edmonton")!
    store = KeptHoursStore(calendar: calendar)
    store.reset()
    LittleHoursSettings.reset()
    center = RemindersCenterMock()
  }

  override func tearDown() {
    store.reset()
    LittleHoursSettings.reset()
    center = nil
    store = nil
    calendar = nil
    super.tearDown()
  }

  private func editor() -> RemindersEditor {
    RemindersEditor(
      reschedule: { [self] in
        OfficeNotificationScheduler(
          center: center, calendar: calendar, store: store
        ).reschedule(from: thursday)
      })
  }

  // MARK: - Editing reschedules

  func testChangingATimePersistsAndMovesThePendingNotices() {
    editor().setTime(13 * 60 + 37, for: .sext)

    XCTAssertEqual(LittleHoursSettings.minutes(for: .sext), 817)
    let sext = center.added
      .filter { $0.identifier.contains("-sext") }
      .compactMap { $0.trigger as? UNCalendarNotificationTrigger }
    XCTAssertFalse(sext.isEmpty)
    for trigger in sext {
      XCTAssertEqual(trigger.dateComponents.hour, 13)
      XCTAssertEqual(trigger.dateComponents.minute, 37)
    }
  }

  func testTogglingAnHourOffRemovesItsNoticesAndBackOnRestoresThem() {
    editor().setEnabled(false, for: .sext)
    XCTAssertTrue(center.identifiers(containing: "-sext").isEmpty)

    center = RemindersCenterMock()
    editor().setEnabled(true, for: .sext)
    // 5 days from Thursday, less the quiet Sunday -> 4 days x 1 hour.
    XCTAssertEqual(center.identifiers(containing: "-sext").count, 4)
  }

  func testTogglingSundaysOnAddsSundayNotices() {
    editor().setRemindsOnSundays(true)
    // 30 August 2026 is the only Sunday in a 5-day window from the 27th.
    XCTAssertEqual(center.identifiers(containing: "2026-08-30").count, 3)
  }

  func testEveryEditReschedules() {
    var rescheduleCount = 0
    let editor = RemindersEditor(reschedule: { rescheduleCount += 1 })

    editor.setTime(600, for: .terce)
    editor.setEnabled(false, for: .nones)
    editor.setRemindsOnSundays(true)
    editor.setRemindsDuringSession(false)

    XCTAssertEqual(
      rescheduleCount, 4, "an edit that does not reschedule does nothing until relaunch")
  }

  func testConductSwitchesPersist() {
    editor().setRemindsDuringSession(false)
    XCTAssertFalse(LittleHoursSettings.remindsDuringSession)
  }

  // MARK: - Authorization

  /// iOS prompts once per install. If the user declined earlier — during
  /// onboarding, say — the toggle would sit "on" while nothing ever fires.
  func testADeniedStatusSurfacesTheSettingsLink() {
    XCTAssertTrue(PrayerRemindersModel.showsSettingsLink(for: .denied))
  }

  func testAnAuthorizedStatusShowsNoLink() {
    XCTAssertFalse(PrayerRemindersModel.showsSettingsLink(for: .authorized))
    XCTAssertFalse(PrayerRemindersModel.showsSettingsLink(for: .provisional))
  }

  func testAnUndeterminedStatusShowsNoLinkBecauseThePromptStillWorks() {
    XCTAssertFalse(PrayerRemindersModel.showsSettingsLink(for: .notDetermined))
  }

  func testTheSettingsNoticeNamesTheApp() {
    XCTAssertEqual(
      PrayerRemindersModel.settingsNotice,
      "Notices are turned off for Sapientia in iOS Settings.")
  }

  // MARK: - The preview card

  func testThePreviewCardMatchesWhatIOSWouldShow() {
    let preview = PrayerRemindersModel.previewNotice()
    XCTAssertEqual(preview.title, "Midday — Sext")
    XCTAssertEqual(preview.body, "The sixth hour. Psalms 123, 124, 125.")
    XCTAssertEqual(preview.time, "12:00")
  }

  func testThePreviewCardFollowsAnEditedTime() {
    LittleHoursSettings.setMinutes(13 * 60 + 37, for: .sext)
    XCTAssertEqual(PrayerRemindersModel.previewNotice().time, "13:37")
  }

  // MARK: - The Collect section

  /// An editor whose reschedules are only counted, so each test can tell the
  /// collect reminder's reschedule from the Little Hours'.
  private func countingEditor(
    office: @escaping () -> Void = {}, collect: @escaping () -> Void
  ) -> RemindersEditor {
    RemindersEditor(reschedule: office, rescheduleCollect: collect)
  }

  func testGivenTheCollectReminder_WhenTurnedOn_ThenItPersistsAndReschedulesOnlyItself() {
    CollectReminderSettings.reset()
    defer { CollectReminderSettings.reset() }
    var office = 0
    var collect = 0
    countingEditor(office: { office += 1 }, collect: { collect += 1 }).setCollectEnabled(true)

    XCTAssertTrue(CollectReminderSettings.isEnabled)
    XCTAssertEqual(collect, 1)
    XCTAssertEqual(office, 0)
  }

  func testGivenThreeTimes_WhenAFourthIsAdded_ThenItIsRefusedWithoutRescheduling() {
    CollectReminderSettings.reset()
    defer { CollectReminderSettings.reset() }
    var collect = 0
    let editor = countingEditor(collect: { collect += 1 })

    XCTAssertTrue(editor.addCollectTime(12 * 60))
    XCTAssertTrue(editor.addCollectTime(18 * 60))
    XCTAssertFalse(editor.addCollectTime(21 * 60))
    XCTAssertFalse(editor.addCollectTime(12 * 60), "a duplicate time is refused too")

    XCTAssertEqual(CollectReminderSettings.times, [360, 720, 1080])
    XCTAssertEqual(collect, 2)
  }

  func testGivenOneTime_WhenItIsRemoved_ThenItIsRefused() {
    CollectReminderSettings.reset()
    defer { CollectReminderSettings.reset() }
    var collect = 0
    let editor = countingEditor(collect: { collect += 1 })

    XCTAssertFalse(editor.removeCollectTime(at: 0))
    XCTAssertEqual(collect, 0)

    editor.addCollectTime(12 * 60)
    XCTAssertTrue(editor.removeCollectTime(at: 0))
    XCTAssertEqual(CollectReminderSettings.times, [720])
  }

  func testCollectEditsPersistAndEachReschedules() {
    CollectReminderSettings.reset()
    defer { CollectReminderSettings.reset() }
    var collect = 0
    let editor = countingEditor(collect: { collect += 1 })

    editor.setCollectDays(.saintsAndFeasts)
    editor.setCollectTime(7 * 60, at: 0)
    editor.setEveningBefore(true)
    editor.setEveningMinutes(19 * 60 + 30)

    XCTAssertEqual(CollectReminderSettings.whichDays, .saintsAndFeasts)
    XCTAssertEqual(CollectReminderSettings.times, [420])
    XCTAssertTrue(CollectReminderSettings.eveningBeforeEnabled)
    XCTAssertEqual(CollectReminderSettings.eveningBeforeMinutes, 1170)
    XCTAssertEqual(collect, 4)
  }

  func testTheCollectSectionSaysHowTheBudgetBehaves() {
    XCTAssertEqual(
      PrayerRemindersModel.collectHorizonCaption,
      "More reminders a day look fewer days ahead; opening Sapientia refills them.")
    XCTAssertEqual(
      CollectReminderDays.allCases.map(PrayerRemindersModel.label(for:)),
      ["Every day", "Saints & feasts", "Feasts"])
  }

  func testANewTimeFollowsTheLastBySixHoursAndSkipsOnesAlreadySet() {
    XCTAssertEqual(PrayerRemindersModel.nextCollectTime(after: [360]), 720)
    XCTAssertEqual(PrayerRemindersModel.nextCollectTime(after: [360, 1080]), 0)
    XCTAssertEqual(PrayerRemindersModel.nextCollectTime(after: [0, 360, 1080]), nil)
  }

  // MARK: - Row copy

  func testRowsDescribeEachHour() {
    let rows = PrayerRemindersModel.rows()
    XCTAssertEqual(
      rows.map(\.title), ["Midmorning — Terce", "Midday — Sext", "Midafternoon — None"])
    XCTAssertEqual(rows.map(\.caption), ["The third hour.", "The sixth hour.", "The ninth hour."])
    XCTAssertEqual(rows.map(\.timeLabel), ["9:00", "12:00", "15:00"])
  }
}
