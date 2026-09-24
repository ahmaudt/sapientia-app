import Foundation
import XCTest

@testable import sapientia

final class TimerDurationTests: XCTestCase {

  // MARK: - Clamping

  func testClampedHoldsWithinBounds() {
    XCTAssertEqual(TimerDuration.clamped(60), 60)
    XCTAssertEqual(TimerDuration.clamped(0), TimerDuration.minimumMinutes)
    XCTAssertEqual(TimerDuration.clamped(-500), TimerDuration.minimumMinutes)
    XCTAssertEqual(TimerDuration.clamped(99_999), TimerDuration.maximumMinutes)
  }

  func testSteppedClampsAtBothEnds() {
    XCTAssertEqual(TimerDuration.stepped(60, by: 5), 65)
    XCTAssertEqual(TimerDuration.stepped(60, by: -5), 55)
    // Stepping below the floor pins to it rather than wrapping or going negative.
    XCTAssertEqual(
      TimerDuration.stepped(TimerDuration.minimumMinutes, by: -5),
      TimerDuration.minimumMinutes)
    XCTAssertEqual(
      TimerDuration.stepped(TimerDuration.maximumMinutes, by: 5),
      TimerDuration.maximumMinutes)
  }

  // MARK: - Clock numeral (the 68pt display)

  func testClockTextUsesHoursAndPaddedMinutes() {
    XCTAssertEqual(TimerDuration.clockText(90), "1:30")
    XCTAssertEqual(TimerDuration.clockText(60), "1:00")
    XCTAssertEqual(TimerDuration.clockText(15), "0:15")
    XCTAssertEqual(TimerDuration.clockText(65), "1:05")
    XCTAssertEqual(TimerDuration.clockText(1439), "23:59")
  }

  // MARK: - Preset tags

  func testCompactTextDropsZeroComponents() {
    XCTAssertEqual(TimerDuration.compactText(30), "30m")
    XCTAssertEqual(TimerDuration.compactText(60), "1h")
    XCTAssertEqual(TimerDuration.compactText(90), "1h 30m")
    XCTAssertEqual(TimerDuration.compactText(180), "3h")
  }

  func testPresetsMatchTheDesignRow() {
    XCTAssertEqual(
      TimerDuration.presetMinutes.map(TimerDuration.compactText),
      ["30m", "1h", "1h 30m", "3h"])
  }

  func testEveryPresetIsWithinBounds() {
    for preset in TimerDuration.presetMinutes {
      XCTAssertEqual(
        TimerDuration.clamped(preset), preset,
        "preset \(preset) falls outside the selectable range")
    }
  }

  // MARK: - Lift time

  func testLiftsAtAddsDurationToStart() {
    let start = Date(timeIntervalSince1970: 1_000_000)
    XCTAssertEqual(
      TimerDuration.liftsAt(90, from: start),
      start.addingTimeInterval(90 * 60))
  }

  // MARK: - Consequence line

  /// The design's copy asserts nothing can end the session early, which is
  /// only true when the stop button is hidden. With it visible the sentence
  /// would be a lie, so the phrasing has to follow the toggle.
  func testConsequenceReflectsWhetherStoppingEarlyIsPossible() {
    let hidden = TimerDuration.consequence(endTime: "11:44", canStopEarly: false)
    XCTAssertEqual(
      hidden, "It lifts at 11:44. Nothing ends it early but an emergency unblock.")

    let visible = TimerDuration.consequence(endTime: "11:44", canStopEarly: true)
    XCTAssertTrue(visible.hasPrefix("It lifts at 11:44."))
    XCTAssertFalse(
      visible.contains("Nothing ends it early"),
      "must not claim the session is unstoppable while the stop button shows")
  }

  // MARK: - Presentation

  /// `startViewUsesFullScreen` replaced a `strategy is NFCScanningStrategy`
  /// check at the call site. These pin both halves: the timer strategies now
  /// opt in, and every strategy that was full-screen before still is.
  func testTimerStrategiesPresentTheDurationScreenFullScreen() {
    XCTAssertTrue(QRTimerBlockingStrategy().startViewUsesFullScreen)
    XCTAssertTrue(ShortcutTimerBlockingStrategy().startViewUsesFullScreen)
    XCTAssertTrue(NFCTimerBlockingStrategy().startViewUsesFullScreen)
  }

  func testNFCScanningStrategiesRemainFullScreen() {
    XCTAssertTrue(NFCBlockingStrategy().startViewUsesFullScreen)
    XCTAssertTrue(NFCManualBlockingStrategy().startViewUsesFullScreen)
    XCTAssertTrue(NFCPauseTimerBlockingStrategy().startViewUsesFullScreen)
    XCTAssertTrue(NFCSoftUnblockBlockingStrategy().startViewUsesFullScreen)
  }

  func testNonScanningStrategiesStillUseDetentSheets() {
    XCTAssertFalse(ManualBlockingStrategy().startViewUsesFullScreen)
    XCTAssertFalse(QRCodeBlockingStrategy().startViewUsesFullScreen)
    XCTAssertFalse(QRManualBlockingStrategy().startViewUsesFullScreen)
    XCTAssertFalse(QRPauseTimerBlockingStrategy().startViewUsesFullScreen)
    XCTAssertFalse(QRSoftUnblockBlockingStrategy().startViewUsesFullScreen)
  }
}
