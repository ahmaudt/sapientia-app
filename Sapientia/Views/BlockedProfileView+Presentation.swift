import SwiftData
import SwiftUI

// The rule editor's picker/sheet/alert presentations, kept out of the main
// view so its body stays a plain list of sections. The set-aside, schedule,
// and strategy pickers are presented full-screen as their tasks convert
// them; the domain picker already is.
extension BlockedProfileView {
  func blockedProfilePresentations(_ content: some View) -> some View {
    content
      .fullScreenCover(isPresented: $showingActivityPicker) {
        AppPicker(
          selection: $draft.selectedActivity,
          isPresented: $showingActivityPicker,
          allowMode: draft.enableAllowMode
        )
      }
      .fullScreenCover(isPresented: $showingDomainPicker) {
        DomainPicker(
          domains: $draft.domains,
          isPresented: $showingDomainPicker,
          allowMode: draft.enableAllowModeDomain
        )
      }
      .fullScreenCover(isPresented: $showingSchedulePicker) {
        SchedulePicker(schedule: $draft.schedule, isPresented: $showingSchedulePicker)
      }
      .fullScreenCover(isPresented: $showingStrategyPicker) {
        StrategyPicker(
          strategies: StrategyManager.availableStrategies,
          selectedStrategy: $draft.selectedStrategy,
          isPresented: $showingStrategyPicker
        )
      }
      .sheet(isPresented: $showingGeneratedQRCode) {
        if let profileToWrite = profile {
          QRCodeView(
            url: BlockedProfiles.getProfileDeepLink(profileToWrite),
            profileName: profileToWrite.name
          )
        }
      }
      .sheet(isPresented: $showingInsights) {
        if let validProfile = profile {
          ProfileInsightsView(profile: validProfile)
        }
      }
      .sheet(isPresented: $showingStrictNFCWriteWarning) {
        StrictNFCWriteWarningView(
          profileName: profile?.name ?? "this profile",
          onCancel: {
            pendingNFCWriteURL = nil
            showingStrictNFCWriteWarning = false
          },
          onContinue: { continuePendingNFCWrite() }
        )
        .presentationDetents([.height(520), .large])
        .presentationDragIndicator(.visible)
      }
      .background(
        TextFieldAlert(
          isPresented: $showingClonePrompt,
          title: "Duplicate Rule",
          message: nil,
          text: $cloneName,
          placeholder: "Rule Name",
          confirmTitle: "Create",
          cancelTitle: "Cancel",
          onConfirm: { enteredName in
            let trimmed = enteredName.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty, let source = profile else { return }
            do {
              let cloned = try BlockedProfiles.cloneProfile(
                source, in: modelContext, newName: trimmed)
              DeviceActivityCenterUtil.scheduleTimerActivity(for: cloned)
            } catch {
              showError(message: error.localizedDescription)
            }
          }
        )
      )
      .alert(item: $alertIdentifier) { alert in
        switch alert.id {
        case .error:
          return Alert(
            title: Text("Error"),
            message: Text(alert.errorMessage ?? "An unknown error occurred"),
            dismissButton: .default(Text("OK"))
          )
        case .deleteProfile:
          return Alert(
            title: Text("Delete Rule"),
            message: Text("Are you sure you want to delete this rule? This cannot be undone."),
            primaryButton: .cancel(),
            secondaryButton: .destructive(Text("Delete")) {
              dismiss()
              if let profileToDelete = profile {
                do {
                  try BlockedProfiles.deleteProfile(profileToDelete, in: modelContext)
                } catch {
                  showError(message: error.localizedDescription)
                }
              }
            }
          )
        }
      }
  }
}
