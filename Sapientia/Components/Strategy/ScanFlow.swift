import Foundation

/// NFC strategies expose their scanner so the scan stage can trigger it
/// (and tests can substitute a spy).
protocol NFCScanningStrategy: AnyObject {
  var nfcScanner: NFCScannerUtil { get set }
}

extension NFCScanningStrategy {
  /// Scan stage for starting a session by tag.
  func makeStartScanStage(for profile: BlockedProfiles) -> ScanSessionView {
    ScanSessionView(
      profileName: profile.name,
      caption: pairedTagName(for: profile),
      needsPrayer: false,
      onReady: { [nfcScanner] in nfcScanner.scan(profileName: profile.name) }
    )
  }

  /// Scan stage for stopping (or pausing) a session by tag, with the
  /// prayer interstitial in front when the profile asks for it.
  func makeStopScanStage(
    for session: BlockedProfileSession,
    scanPrompt: String? = nil,
    qrFallbackHandler: ((String) -> Void)? = nil
  ) -> ScanSessionView {
    let profile = session.blockedProfile
    return ScanSessionView(
      profileName: profile.name,
      caption: pairedTagName(for: profile),
      needsPrayer: ScanFlow.needsPrayer(
        isStopping: true,
        prayBeforeUnblocking: profile.prayBeforeUnblockingResolved
      ),
      onReady: { [nfcScanner] in
        nfcScanner.scan(profileName: scanPrompt ?? profile.name)
      },
      qrFallbackHandler: qrFallbackHandler
    )
  }

  private func pairedTagName(for profile: BlockedProfiles) -> String? {
    profile.physicalUnblockItems?.first { $0.type == .nfc }?.name
  }
}

/// Pure decisions for the scan/prayer flow. Kept free of UI so they are
/// unit-testable.
enum ScanFlow {

  /// The prayer stands before UNblocking: it gates stops, never starts.
  static func needsPrayer(isStopping: Bool, prayBeforeUnblocking: Bool) -> Bool {
    isStopping && prayBeforeUnblocking
  }

  /// Deep-link toggles (NFC tag scanned from the home screen) stop the
  /// active session — gate them the same way.
  static func deeplinkNeedsPrayer(
    hasActiveSession: Bool, activeProfilePrays: Bool
  ) -> Bool {
    hasActiveSession && activeProfilePrays
  }
}
