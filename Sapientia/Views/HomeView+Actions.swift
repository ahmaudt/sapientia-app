import SwiftData
import SwiftUI

// HomeView behavior: session toggling, deep-link prayer gating, alert
// plumbing, and the strategy-view presentation bindings.
extension HomeView {

  /// The full sheet / full-screen-cover / alert presentation stack for
  /// Home, applied to the scrollable content.
  @ViewBuilder
  func homePresentations(_ content: some View) -> some View {
    content
      .sheet(item: $alertsManager.selectedAlert) { alert in
        HomeAlertDetailView(
          alert: alert,
          disabledReason: disabledReason(for: alert),
          onPrimaryAction: {
            runAlertPrimaryAction(for: alert)
          }
        )
        .presentationDetents([.medium, .large])
      }
      .fullScreenCover(isPresented: $showIntroScreen) {
        IntroView {
          requestAuthorizer.requestAuthorization()
        }.interactiveDismissDisabled()
      }
      .fullScreenCover(isPresented: $showActiveProfileSessionView) {
        if let activeProfile = strategyManager.activeSession?.blockedProfile {
          ActiveProfileSessionView(
            profile: activeProfile,
            elapsedTime: strategyManager.elapsedTime,
            displayTime: strategyManager.sessionDisplayTime,
            isBreakAvailable: isBreakAvailable,
            isBreakActive: isBreakActive,
            isPauseActive: isPauseActive,
            onBreakTapped: {
              strategyManager.toggleBreak(context: context)
            },
            onStopTapped: {
              strategyButtonPress(activeProfile)
            }
          )
        }
      }
      .sheet(item: $profileToShowStats) { profile in
        ProfileInsightsView(profile: profile)
      }
      .sheet(item: $profileToEdit) { profile in
        BlockedProfileView(profile: profile)
      }
      .sheet(item: $dashboardInsightsContext) { context in
        ProfileInsightsView(
          profile: context.profile,
          initialViewMode: context.viewMode,
          initialSelectedDate: context.selectedDate
        )
      }
      .sheet(isPresented: $showNewProfileView) {
        BlockedProfileView(profile: nil)
      }
      .sheet(isPresented: $showGuidedProfileCreationView) {
        GuidedBlockedProfileCreationView()
      }
      .sheet(isPresented: $showStartProfilePicker) {
        StartProfilePickerView(
          profiles: profiles,
          isBlocking: isBlocking,
          activeSessionProfileId: activeSessionProfileId,
          startingProfileId: navigateToProfileId,
          onGoTapped: { profile in
            startProfile(profile)
          }
        )
        .presentationDetents([.medium, .large])
      }
      .sheet(isPresented: strategyActionSheetBinding) {
        BlockingStrategyActionView(
          customView: strategyManager.customStrategyView,
          presentationDetents: strategyManager.customStrategyViewPresentationDetents
        )
      }
      .fullScreenCover(isPresented: strategyActionFullScreenBinding) {
        if let view = strategyManager.customStrategyView {
          AnyView(view)
        }
      }
      .fullScreenCover(item: $pendingDeeplink) { deeplink in
        PrayerInterstitialView(
          onAmen: {
            toggleSessionFromDeeplink(deeplink.profileId, link: deeplink.url)
            pendingDeeplink = nil
          },
          onCancel: {
            pendingDeeplink = nil
          }
        )
      }
      .sheet(isPresented: $showDonationView) {
        SupportView()
      }
      .sheet(isPresented: $showSettingsView) {
        SettingsView()
      }
      .alert(alertTitle, isPresented: $showingAlert) {
        Button("OK", role: .cancel) { dismissAlert() }
      } message: {
        Text(alertMessage)
      }
  }

  /// NFC tag scans from the home screen arrive as deep links and stop the
  /// session directly — when the active profile prays before unblocking,
  /// the prayer stands in front of that path too.
  func handleDeeplinkToggle(_ profileId: String, link: URL) {
    let activeProfilePrays =
      strategyManager.activeSession?.blockedProfile.prayBeforeUnblockingResolved ?? false
    if ScanFlow.deeplinkNeedsPrayer(
      hasActiveSession: isBlocking, activeProfilePrays: activeProfilePrays)
    {
      pendingDeeplink = PendingDeeplink(profileId: profileId, url: link)
    } else {
      toggleSessionFromDeeplink(profileId, link: link)
    }
  }

  func toggleSessionFromDeeplink(_ profileId: String, link: URL) {
    strategyManager
      .toggleSessionFromDeeplink(profileId, url: link, context: context)
  }

  func strategyButtonPress(_ profile: BlockedProfiles) {
    strategyManager
      .toggleBlocking(context: context, activeProfile: profile)

    ratingManager.incrementLaunchCount()
  }

  var strategyActionSheetBinding: Binding<Bool> {
    Binding(
      get: {
        strategyManager.showCustomStrategyView
          && !strategyManager.customStrategyViewUsesFullScreen
          && !showActiveProfileSessionView
      },
      set: { isPresented in
        if !isPresented {
          strategyManager.showCustomStrategyView = false
        }
      }
    )
  }

  var strategyActionFullScreenBinding: Binding<Bool> {
    Binding(
      get: {
        strategyManager.showCustomStrategyView
          && strategyManager.customStrategyViewUsesFullScreen
          && !showActiveProfileSessionView
      },
      set: { isPresented in
        if !isPresented {
          strategyManager.showCustomStrategyView = false
        }
      }
    )
  }

  func startProfile(_ profile: BlockedProfiles) {
    guard !isBlocking else {
      showErrorAlert(message: "Stop the active profile before starting another one.")
      return
    }

    strategyButtonPress(profile)
  }

  func loadApp() {
    strategyManager.loadActiveSession(context: context)
  }

  func onAppearApp() {
    requestAuthorizer.refreshAuthorizationStatus()
    strategyManager.loadActiveSession(context: context)
    strategyManager.cleanUpGhostSchedules(context: context)
    refreshAlerts()
    FeastNotificationScheduler().reschedule()
  }

  func refreshAlerts() {
    alertsManager.refreshAlerts(
      profiles: profiles,
      authorizationStatus: requestAuthorizer.getAuthorizationStatus()
    )
  }

  func presentAlert(_ alert: HomeAlert) {
    alertsManager.present(alert)
  }

  func disabledReason(for alert: HomeAlert) -> String? {
    return alertsManager.disabledReason(
      for: alert,
      profiles: profiles,
      isBlocking: isBlocking
    )
  }

  func runAlertPrimaryAction(for alert: HomeAlert) {
    alertsManager.runPrimaryAction(
      for: alert,
      profiles: profiles,
      isBlocking: isBlocking,
      requestAuthorizer: requestAuthorizer,
      onScheduleRepaired: {
        loadApp()
        refreshAlerts()
      }
    )
  }

  func unloadApp() {
    strategyManager.stopTimer()
  }

  func showErrorAlert(message: String) {
    alertTitle = "Whoops"
    alertMessage = message
    showingAlert = true
  }

  func dismissAlert() {
    showingAlert = false
    strategyManager.errorMessage = nil
  }
}
