import SwiftData
import SwiftUI

class NFCManualBlockingStrategy: BlockingStrategy, NFCScanningStrategy {
  static var id: String = "NFCManualBlockingStrategy"

  var name: String = "NFC + Manual"
  var description: String =
    "Start in the app. To stop, scan any NFC tag. Use Strict Unlocks if you want only selected tags to work."
  var iconAssetName: String = "Manual+NFCSticker"
  var color: Color = .yellow
  var pickerCategory: BlockingStrategyPickerCategory = .easyToStart

  var usesNFC: Bool = true
  var startsManually: Bool = true

  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?

  var nfcScanner: NFCScannerUtil = NFCScannerUtil()
  private let appBlocker: AppBlockerUtil = AppBlockerUtil()

  func getIdentifier() -> String {
    return NFCManualBlockingStrategy.id
  }

  func startBlocking(
    context: ModelContext,
    profile: BlockedProfiles,
    forceStart: Bool?
  ) -> (any View)? {
    self.appBlocker.activateRestrictions(for: BlockedProfiles.getSnapshot(for: profile))

    let activeSession =
      BlockedProfileSession
      .createSession(
        in: context,
        // Manually starting sessions, since nothing was scanned to start there is no tag to store for each session
        withTag: ManualBlockingStrategy.id,
        withProfile: profile,
        forceStart: forceStart ?? false
      )

    self.onSessionCreation?(.started(activeSession))

    return nil
  }

  func stopBlocking(
    context: ModelContext,
    session: BlockedProfileSession
  ) -> (any View)? {
    nfcScanner.onTagScanned = { tag in
      let tag = tag.url ?? tag.id

      if session.blockedProfile.hasPhysicalUnblockItem(ofType: .nfc)
        && !session.blockedProfile.canUnblock(withCode: tag, type: .nfc)
      {
        self.onErrorMessage?(
          "This NFC tag is not allowed to unblock this profile. Physical unblock setting is on for this profile"
        )
        return
      }

      session.endSession()
      try? context.save()
      self.appBlocker.deactivateRestrictions()

      self.onSessionCreation?(.ended(session.blockedProfile))
    }

    return makeStopScanStage(
      for: session,
      qrFallbackHandler: qrFallbackHandler(for: session)
    )
  }

  /// Any paired QR code closes the session just the same (mockup 04).
  private func qrFallbackHandler(
    for session: BlockedProfileSession
  ) -> ((String) -> Void)? {
    guard session.blockedProfile.hasPhysicalUnblockItem(ofType: .qrCode) else {
      return nil
    }
    return { code in
      guard session.blockedProfile.canUnblock(withCode: code, type: .qrCode) else {
        self.onErrorMessage?(
          "This QR code is not allowed to unblock this profile.")
        return
      }
      session.endSession()
      try? session.modelContext?.save()
      self.appBlocker.deactivateRestrictions()
      self.onSessionCreation?(.ended(session.blockedProfile))
    }
  }
}
