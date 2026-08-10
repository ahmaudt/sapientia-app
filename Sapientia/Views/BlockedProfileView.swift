import FamilyControls
import Foundation
import SwiftData
import SwiftUI

// Alert identifier for managing multiple alerts
struct AlertIdentifier: Identifiable {
  enum AlertType {
    case error
    case deleteProfile
  }

  let id: AlertType
  var errorMessage: String?
}

/// Screen 07 — the rule editor. A `BlueprintStage` of ruled sections; every
/// Foqos option is kept, only its presentation changed. Sheet/cover/alert
/// modifiers live in `BlockedProfileView+Presentation.swift`.
struct BlockedProfileView: View {
  @Environment(\.modelContext) var modelContext
  @Environment(\.dismiss) var dismiss

  @EnvironmentObject var nfcWriter: NFCWriter
  @EnvironmentObject var strategyManager: StrategyManager

  // If profile is nil, we're creating a new profile
  var profile: BlockedProfiles?

  @StateObject var draft: BlockedProfileDraft

  @State var showingGeneratedQRCode = false
  @State var showingActivityPicker = false
  @State var showingDomainPicker = false
  @State var showingSchedulePicker = false
  @State var showingStrategyPicker = false
  @State var alertIdentifier: AlertIdentifier?
  @State var pendingNFCWriteURL: String?
  @State var showingStrictNFCWriteWarning = false
  @State var showingClonePrompt = false
  @State var cloneName: String = ""
  @State var showingInsights = false

  var isEditing: Bool { profile != nil }
  var isBlocking: Bool { strategyManager.activeSession?.isActive ?? false }

  init(profile: BlockedProfiles? = nil) {
    self.profile = profile
    _draft = StateObject(wrappedValue: BlockedProfileDraft(profile: profile))
  }

  var body: some View {
    blockedProfilePresentations(stage)
  }

  private var stage: some View {
    BlueprintStage(
      title: draft.name.isEmpty ? (isEditing ? "Edit rule" : "New session") : draft.name,
      leadingLabel: "Cancel",
      leadingAction: { dismiss() },
      trailingLabel: (isEditing && !isBlocking) ? "Save" : nil,
      trailingAction: { saveProfile() }
    ) {
      VStack(alignment: .leading, spacing: SapientiaTheme.space6) {
        if isBlocking { activeNotice }

        BlockedProfileNameSection(draft: draft, disabled: false)
        BlockedProfileAppsSection(
          draft: draft, showingActivityPicker: $showingActivityPicker, disabled: isBlocking)
        BlockedProfileDomainsSection(
          draft: draft, showingDomainPicker: $showingDomainPicker, disabled: isBlocking)
        BlockedProfileStrategySection(
          draft: draft, showingStrategyPicker: $showingStrategyPicker, disabled: isBlocking)
        BlockedProfileStrictUnlocksSection(draft: draft, disabled: isBlocking)
        BlockedProfileScheduleSection(
          draft: draft, showingSchedulePicker: $showingSchedulePicker, disabled: isBlocking)
        BlockedProfileBreaksSection(draft: draft, disabled: isBlocking)
        BlockedProfileStrictSafeguardsSection(draft: draft, disabled: isBlocking)
        BlockedProfileSessionSafeguardsSection(draft: draft, disabled: isBlocking)
        BlockedProfileNotificationsSection(draft: draft, profile: profile, disabled: isBlocking)

        if isEditing && !isBlocking { editActions }
      }
    } bottom: {
      if !isBlocking && !isEditing {
        Button(primaryCTATitle) { saveAndBegin() }
          .buttonStyle(BlueprintPrimaryButtonStyle())
          .disabled(!draft.isValid)
      }
    }
  }

  private var activeNotice: some View {
    BlueprintCard {
      VStack(alignment: .leading, spacing: 4) {
        Text("A session is active")
          .font(.sapientiaHeading(17))
          .foregroundColor(SapientiaTheme.text)
        Text("Stop it before editing this rule.")
          .font(.sapientiaBody(13))
          .foregroundColor(SapientiaTheme.text.opacity(0.62))
      }
    }
  }

  @ViewBuilder
  private var editActions: some View {
    VStack(alignment: .leading, spacing: 0) {
      SectionHeaderLabel(title: "This rule")
      BlueprintListRow(title: "Write to an NFC tag", onTap: { writeProfile() }) {
        BlueprintRowValue(value: "Tag")
      }
      BlueprintListRow(title: "Generate a QR code", onTap: { showingGeneratedQRCode = true }) {
        BlueprintRowValue(value: "Code")
      }
      BlueprintListRow(
        title: "Duplicate",
        onTap: {
          cloneName = (profile?.name ?? "Rule") + " Copy"
          showingClonePrompt = true
        }
      ) { BlueprintRowValue(value: "Copy") }
      BlueprintListRow(title: "Observance", onTap: { showingInsights = true }) {
        BlueprintRowValue(value: "Record")
      }
      Button("Delete this rule") {
        alertIdentifier = AlertIdentifier(id: .deleteProfile)
      }
      .font(.sapientiaBody(15))
      .foregroundColor(SapientiaTheme.accent700)
      .padding(.vertical, SapientiaTheme.space4)
    }
  }

  var primaryCTATitle: String {
    if isEditing { return "Save" }
    switch draft.strategyFamily {
    case .nfc: return "Begin — tap your tag"
    case .qr: return "Begin — scan your code"
    case .timer: return "Begin"
    }
  }

  func saveProfile() {
    do {
      _ = try draft.save(existingProfile: profile, in: modelContext)
      dismiss()
    } catch {
      alertIdentifier = AlertIdentifier(id: .error, errorMessage: error.localizedDescription)
    }
  }

  /// Create-mode CTA: persist the profile, dismiss, and immediately start
  /// the session (leading into the scan stage for NFC/QR strategies).
  func saveAndBegin() {
    do {
      let savedProfile = try draft.save(existingProfile: profile, in: modelContext)
      dismiss()
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
        strategyManager.toggleBlocking(context: modelContext, activeProfile: savedProfile)
      }
    } catch {
      alertIdentifier = AlertIdentifier(id: .error, errorMessage: error.localizedDescription)
    }
  }

  func showError(message: String) {
    alertIdentifier = AlertIdentifier(id: .error, errorMessage: message)
  }

  func writeProfile() {
    guard let profileToWrite = profile else { return }
    let url = BlockedProfiles.getProfileDeepLink(profileToWrite)
    if shouldWarnBeforeNFCWrite(for: profileToWrite) {
      pendingNFCWriteURL = url
      showingStrictNFCWriteWarning = true
    } else {
      nfcWriter.writeURL(url)
    }
  }

  func shouldWarnBeforeNFCWrite(for profile: BlockedProfiles) -> Bool {
    profile.hasPhysicalUnblockItem(ofType: .nfc)
  }

  func continuePendingNFCWrite() {
    guard let url = pendingNFCWriteURL else {
      showingStrictNFCWriteWarning = false
      return
    }
    pendingNFCWriteURL = nil
    showingStrictNFCWriteWarning = false
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
      nfcWriter.writeURL(url)
    }
  }
}

#Preview {
  BlockedProfileView()
    .environmentObject(NFCWriter())
    .environmentObject(StrategyManager())
    .modelContainer(for: BlockedProfiles.self, inMemory: true)
}
