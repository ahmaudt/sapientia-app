import SwiftData
import SwiftUI

class NFCBlockingStrategy: BlockingStrategy, NFCScanningStrategy {
  static var id: String = "NFCBlockingStrategy"

  var name: String = "NFC Tags"
  var description: String = "Start by scanning an NFC tag. To stop, scan the same tag again."
  var iconAssetName: String = "NFCStickerLogo"
  var color: Color = .yellow
  var pickerCategory: BlockingStrategyPickerCategory = .mostPopular

  var usesNFC: Bool = true
  var requiresSameCodeToStop: Bool = true

  var onSessionCreation: ((SessionStatus) -> Void)?
  var onErrorMessage: ((String) -> Void)?

  var nfcScanner: NFCScannerUtil = NFCScannerUtil()
  private let appBlocker: AppBlockerUtil = AppBlockerUtil()

  func getIdentifier() -> String {
    return NFCBlockingStrategy.id
  }

  func startBlocking(
    context: ModelContext,
    profile: BlockedProfiles,
    forceStart: Bool?
  ) -> (any View)? {
    nfcScanner.onTagScanned = { tag in
      self.appBlocker.activateRestrictions(for: BlockedProfiles.getSnapshot(for: profile))

      let tag = tag.url ?? tag.id
      let activeSession =
        BlockedProfileSession
        .createSession(
          in: context,
          withTag: tag,
          withProfile: profile,
          forceStart: forceStart ?? false
        )
      self.onSessionCreation?(.started(activeSession))
    }

    return makeStartScanStage(for: profile)
  }

  func stopBlocking(
    context: ModelContext,
    session: BlockedProfileSession
  ) -> (any View)? {
    nfcScanner.onTagScanned = { tag in
      let tag = tag.url ?? tag.id

      if session.blockedProfile.hasPhysicalUnblockItem(ofType: .nfc) {
        if !session.blockedProfile.canUnblock(withCode: tag, type: .nfc) {
          self.onErrorMessage?(
            "This NFC tag is not allowed to unblock this profile. Physical unblock setting is on for this profile"
          )
          return
        }
      } else if !session.forceStarted && session.tag != tag {
        // No physical unblock tag - must use original session tag (unless force started)
        self.onErrorMessage?(
          "You must scan the original tag to stop focus"
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
