//
//  ShieldConfigurationExtension.swift
//  SapientiaShieldConfig
//

import ManagedSettings
import ManagedSettingsUI
import SwiftUI
import UIKit

// The shield presents a prayer — the Prayer of St. Benedict or the Collect
// of the day — on the design system's accent-900 ground. All copy comes
// from ShieldContent (shared, unit-tested); this file only maps it onto
// ShieldConfiguration. Make sure the class name matches the
// NSExtensionPrincipalClass in Info.plist.
class ShieldConfigurationExtension: ShieldConfigurationDataSource {

  private enum Palette {
    static let ground = UIColor(Color(hex: "#1d2d3d"))  // accent-900
    static let accent = UIColor(Color(hex: "#5980a6"))
    static let kicker = UIColor(Color(hex: "#b5d9fd"))  // accent-300
    static let foreground = UIColor(Color(hex: "#f2f2f3"))
  }

  override func configuration(shielding application: Application) -> ShieldConfiguration {
    if let softUnblockConfiguration = softUnblockConfiguration(for: application, in: nil) {
      return softUnblockConfiguration
    }
    return prayerConfiguration(blockedItemName: application.localizedDisplayName ?? "This app")
  }

  override func configuration(shielding application: Application, in category: ActivityCategory)
    -> ShieldConfiguration
  {
    if let softUnblockConfiguration = softUnblockConfiguration(for: application, in: category) {
      return softUnblockConfiguration
    }
    return prayerConfiguration(blockedItemName: application.localizedDisplayName ?? "This app")
  }

  override func configuration(shielding webDomain: WebDomain) -> ShieldConfiguration {
    return prayerConfiguration(blockedItemName: webDomain.domain ?? "This website")
  }

  override func configuration(shielding webDomain: WebDomain, in category: ActivityCategory)
    -> ShieldConfiguration
  {
    return prayerConfiguration(blockedItemName: webDomain.domain ?? "This website")
  }

  // MARK: - Prayer shield

  private func prayerConfiguration(blockedItemName: String) -> ShieldConfiguration {
    let shield = ShieldContent.prayerShield(
      prayer: PrayerSettings.blockScreenPrayer,
      date: Date(),
      blockedItemName: blockedItemName,
      unblockPhrase: activeSessionUnblockPhrase()
    )

    return ShieldConfiguration(
      backgroundBlurStyle: .dark,
      backgroundColor: Palette.ground,
      icon: nil,
      title: ShieldConfiguration.Label(text: shield.title, color: Palette.kicker),
      subtitle: ShieldConfiguration.Label(
        text: shield.subtitle,
        color: Palette.foreground.withAlphaComponent(0.92)
      ),
      primaryButtonLabel: ShieldConfiguration.Label(
        text: shield.buttonText,
        color: Palette.foreground
      ),
      primaryButtonBackgroundColor: Palette.accent,
      secondaryButtonLabel: nil
    )
  }

  private func activeSessionUnblockPhrase() -> String {
    guard
      let session = SharedData.getActiveSharedSession(),
      let snapshot = SharedData.snapshot(for: session.blockedProfileId.uuidString),
      let items = PhysicalUnblockItem.resolvedItems(
        physicalUnblockItems: snapshot.physicalUnblockItems)
    else {
      return ShieldContent.unblockPhrase(hasNFCTag: false, hasQRCode: false)
    }
    return ShieldContent.unblockPhrase(
      hasNFCTag: items.contains { $0.type == .nfc },
      hasQRCode: items.contains { $0.type == .qrCode }
    )
  }

  // MARK: - Soft unblock

  private func softUnblockConfiguration(
    for application: Application,
    in category: ActivityCategory?
  ) -> ShieldConfiguration? {
    guard let session = SoftUnblockGrantStore.activeSession,
      let snapshot = SharedData.snapshot(for: session.profileId.uuidString),
      let presentation = softUnblockPresentation(
        for: application,
        in: category,
        profile: snapshot
      ),
      !SoftUnblockGrantStore.hasActiveGrant(
        for: presentation.resource,
        profileId: session.profileId
      )
    else {
      return nil
    }

    let configuration = SoftUnblockStrategyData.decode(snapshot.strategyData)
    guard session.remainingUnblockCount > 0 else {
      let shield = ShieldContent.softUnblockExhausted(
        maximum: session.maximumUnblockCount,
        resetDescription: allowanceResetDescription(for: session)
      )
      return softUnblockShieldConfiguration(shield, secondaryButton: nil)
    }

    let resourceName =
      application.localizedDisplayName ?? presentation.resourceName
    let shield = ShieldContent.softUnblockShield(
      resourceName: resourceName,
      remaining: session.remainingUnblockCount,
      maximum: session.maximumUnblockCount,
      accessMinutes: configuration.accessDurationInMinutes,
      resetDescription: allowanceResetDescription(for: session)
    )
    return softUnblockShieldConfiguration(shield, secondaryButton: "Back")
  }

  private func softUnblockShieldConfiguration(
    _ shield: ShieldContent.Shield,
    secondaryButton: String?
  ) -> ShieldConfiguration {
    return ShieldConfiguration(
      backgroundBlurStyle: .dark,
      backgroundColor: Palette.ground,
      icon: nil,
      title: ShieldConfiguration.Label(text: shield.title, color: Palette.kicker),
      subtitle: ShieldConfiguration.Label(
        text: shield.subtitle,
        color: Palette.foreground.withAlphaComponent(0.92)
      ),
      primaryButtonLabel: ShieldConfiguration.Label(
        text: shield.buttonText,
        color: Palette.foreground
      ),
      primaryButtonBackgroundColor: Palette.accent,
      secondaryButtonLabel: secondaryButton.map {
        ShieldConfiguration.Label(text: $0, color: Palette.foreground)
      }
    )
  }

  private func allowanceResetDescription(for session: SoftUnblockSessionState) -> String? {
    guard session.allowanceResetIntervalInHours != nil,
      let nextAllowanceResetAt = session.nextAllowanceResetAt
    else {
      return nil
    }

    let remainingMinutes = max(
      Int(ceil(nextAllowanceResetAt.timeIntervalSinceNow / 60)),
      1
    )
    if remainingMinutes >= 60 {
      return "Resets in \(remainingMinutes / 60)h"
    }
    return "Resets in \(remainingMinutes)m"
  }

  private func softUnblockPresentation(
    for application: Application,
    in category: ActivityCategory?,
    profile: SharedData.ProfileSnapshot
  ) -> (resource: SoftUnblockResource, resourceName: String)? {
    if let categoryToken = category?.token {
      guard !profile.enableAllowMode else { return nil }

      let categoryName = category?.localizedDisplayName ?? "this category"
      return (
        resource: .category(categoryToken),
        resourceName: categoryName
      )
    }

    guard let applicationToken = application.token else { return nil }
    let applicationName = application.localizedDisplayName ?? "this app"
    return (
      resource: .application(applicationToken),
      resourceName: applicationName
    )
  }
}
