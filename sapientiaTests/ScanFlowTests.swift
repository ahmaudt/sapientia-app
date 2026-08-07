import SwiftData
import SwiftUI
import XCTest

@testable import sapientia

private final class NFCScannerSpy: NFCScannerUtil {
  private(set) var scanCallCount = 0

  override func scan(profileName: String) {
    scanCallCount += 1
  }
}

final class ScanFlowTests: XCTestCase {

  private func makeContext() throws -> ModelContext {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try ModelContainer(
      for: BlockedProfileSession.self,
      BlockedProfiles.self,
      configurations: configuration
    )
    return ModelContext(container)
  }

  // MARK: - Prayer gating decisions

  func testPrayerGatesStopWhenEnabled() {
    XCTAssertTrue(ScanFlow.needsPrayer(isStopping: true, prayBeforeUnblocking: true))
  }

  func testPrayerDoesNotGateStart() {
    // The prayer stands before UNblocking, not before starting a session.
    XCTAssertFalse(ScanFlow.needsPrayer(isStopping: false, prayBeforeUnblocking: true))
  }

  func testPrayerDisabledDoesNotGate() {
    XCTAssertFalse(ScanFlow.needsPrayer(isStopping: true, prayBeforeUnblocking: false))
  }

  // MARK: - NFC strategies defer the scan to the scan stage

  func testNFCStartBlockingReturnsViewWithoutFiringScanner() throws {
    let context = try makeContext()
    let profile = BlockedProfiles(name: "Deep Work")
    context.insert(profile)
    try context.save()

    let spy = NFCScannerSpy()
    let strategy = NFCBlockingStrategy()
    strategy.nfcScanner = spy

    let view = strategy.startBlocking(context: context, profile: profile, forceStart: false)
    XCTAssertNotNil(view, "NFC start must return the scan stage view")
    XCTAssertEqual(spy.scanCallCount, 0, "Scanner must not fire until the stage appears")
  }

  func testNFCStopBlockingReturnsViewWithoutFiringScanner() throws {
    let context = try makeContext()
    let profile = BlockedProfiles(name: "Deep Work")
    context.insert(profile)
    let session = BlockedProfileSession.createSession(
      in: context, withTag: "tag", withProfile: profile)
    try context.save()

    let spy = NFCScannerSpy()
    let strategy = NFCBlockingStrategy()
    strategy.nfcScanner = spy

    let view = strategy.stopBlocking(context: context, session: session)
    XCTAssertNotNil(view, "NFC stop must return the scan stage view")
    XCTAssertEqual(spy.scanCallCount, 0, "Scanner must not fire until the stage appears")
  }

  func testAllNFCStrategyStopsDeferTheScan() throws {
    // Every NFC strategy scans on stop; none may fire the scanner before
    // the scan stage appears. (Starts differ by design: manual starts
    // immediately, timer/pause/soft-unblock show configuration views.)
    let context = try makeContext()
    let profile = BlockedProfiles(name: "Deep Work")
    context.insert(profile)
    let session = BlockedProfileSession.createSession(
      in: context, withTag: "tag", withProfile: profile)
    try context.save()

    let strategies: [any BlockingStrategy & NFCScanningStrategy] = [
      NFCBlockingStrategy(),
      NFCManualBlockingStrategy(),
      NFCTimerBlockingStrategy(),
      NFCPauseTimerBlockingStrategy(),
      NFCSoftUnblockBlockingStrategy(),
    ]

    for index in strategies.indices {
      let spy = NFCScannerSpy()
      strategies[index].nfcScanner = spy
      let view = strategies[index].stopBlocking(context: context, session: session)
      XCTAssertNotNil(view, "\(type(of: strategies[index])) stop must return a view")
      XCTAssertEqual(
        spy.scanCallCount, 0, "\(type(of: strategies[index])) must defer the scan")
    }
  }

  // MARK: - Deep-link prayer gating

  func testDeeplinkStopGatedWhenPrayerEnabled() {
    XCTAssertTrue(
      ScanFlow.deeplinkNeedsPrayer(hasActiveSession: true, activeProfilePrays: true))
    XCTAssertFalse(
      ScanFlow.deeplinkNeedsPrayer(hasActiveSession: true, activeProfilePrays: false))
    XCTAssertFalse(
      ScanFlow.deeplinkNeedsPrayer(hasActiveSession: false, activeProfilePrays: true))
  }
}
