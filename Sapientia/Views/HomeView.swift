import SwiftData
import SwiftUI

struct HomeView: View {
  @Environment(\.modelContext) var context
  @Environment(\.openURL) var openURL

  @Environment(\.scenePhase) private var scenePhase

  @EnvironmentObject var requestAuthorizer: RequestAuthorizer
  @EnvironmentObject var strategyManager: StrategyManager
  @EnvironmentObject var alertsManager: AlertsManager
  @EnvironmentObject var navigationManager: NavigationManager
  @EnvironmentObject var ratingManager: RatingManager

  // Profile management
  @Query(sort: [
    SortDescriptor(\BlockedProfiles.order, order: .forward),
    SortDescriptor(\BlockedProfiles.createdAt, order: .reverse),
  ])
  var profiles: [BlockedProfiles]
  @State private var isProfileListPresent = false

  // New profile view
  @State var showNewProfileView = false
  @State var showGuidedProfileCreationView = false
  @State var showStartProfilePicker = false

  // Edit profile
  @State var profileToEdit: BlockedProfiles? = nil

  // Stats sheet
  @State var profileToShowStats: BlockedProfiles? = nil

  // Dashboard insights sheet
  @State var dashboardInsightsContext: DashboardInsightsContext? = nil

  // Donation View
  @State var showDonationView = false

  // Settings View
  @State var showSettingsView = false

  // Active session view
  @State var showActiveProfileSessionView = false

  // Navigate to profile
  @State var navigateToProfileId: UUID? = nil

  // Deep-link unblock held behind the prayer interstitial
  struct PendingDeeplink: Identifiable {
    let id = UUID()
    let profileId: String
    let url: URL
  }
  @State var pendingDeeplink: PendingDeeplink? = nil

  // Activity sessions
  @Query(
    filter: #Predicate<BlockedProfileSession> { $0.endTime != nil },
    sort: \BlockedProfileSession.endTime,
    order: .reverse
  ) private var recentCompletedSessions: [BlockedProfileSession]

  // Alerts
  @State var showingAlert = false
  @State var alertTitle = ""
  @State var alertMessage = ""

  // Intro sheet
  @AppStorage("showIntroScreen") var showIntroScreen = true

  // UI States
  @State private var opacityValue = 1.0

  var isBlocking: Bool {
    return strategyManager.isBlocking
  }

  var activeSessionProfileId: UUID? {
    return strategyManager.activeSession?.blockedProfile.id
  }

  var isBreakAvailable: Bool {
    return strategyManager.isBreakAvailable
  }

  var isBreakActive: Bool {
    return strategyManager.isBreakActive
  }

  var isPauseActive: Bool {
    return strategyManager.isPauseActive
  }

  private var canCreateProfiles: Bool {
    return !isBlocking
  }

  var body: some View {
    homePresentations(mainStack)
  }

  private var mainStack: some View {
    HomeScreenContent(
      profiles: profiles,
      recentCompletedSessions: recentCompletedSessions,
      alerts: alertsManager.alerts,
      isBlocking: isBlocking,
      activeSessionProfileId: activeSessionProfileId,
      emergencyUnblocksRemaining: strategyManager.getRemainingEmergencyUnblocks(),
      actions: HomeScreenActions(
        onSettings: { showSettingsView = true },
        onAlertTapped: { alert in presentAlert(alert) },
        onGuidedCreate: {
          if canCreateProfiles {
            showGuidedProfileCreationView = true
          }
        },
        onAdvancedCreate: {
          if canCreateProfiles {
            showNewProfileView = true
          }
        },
        onStart: { profile in startProfile(profile) },
        onStop: { profile in strategyButtonPress(profile) },
        onEdit: { profile in profileToEdit = profile },
        onStats: { profile in profileToShowStats = profile },
        onManage: { isProfileListPresent = true },
        onInsights: { profile in
          dashboardInsightsContext = DashboardInsightsContext(
            profile: profile,
            viewMode: .week,
            selectedDate: Date()
          )
        },
        onNewSession: { showStartProfilePicker = true }
      )
    )
    .refreshable {
      loadApp()
    }
    .safeAreaInset(edge: .bottom) {
      if !profiles.isEmpty && isBlocking {
        HomeProfileLauncher(
          activeProfile: strategyManager.activeSession?.blockedProfile,
          displayTime: strategyManager.sessionDisplayTime,
          isBreakActive: isBreakActive,
          isPauseActive: isPauseActive,
          onStartTapped: {
            showStartProfilePicker = true
          },
          onActiveTapped: {
            showActiveProfileSessionView = true
          }
        )
      }
    }
    .padding(.top, 1)
    .sheet(
      isPresented: $isProfileListPresent,
    ) {
      BlockedProfileListView()
    }
    .frame(
      minWidth: 0,
      maxWidth: .infinity,
      minHeight: 0,
      maxHeight: .infinity,
      alignment: .topLeading
    )
    .onChange(of: navigationManager.profileId) { _, newValue in
      if let profileId = newValue, let url = navigationManager.link {
        handleDeeplinkToggle(profileId, link: url)
        navigationManager.clearNavigation()
      }
    }
    .onChange(of: navigationManager.navigateToProfileId) { _, newValue in
      if let profileId = newValue {
        navigateToProfileId = UUID(uuidString: profileId)
        showStartProfilePicker = true
        navigationManager.clearNavigation()
      }
    }
    .onChange(of: requestAuthorizer.isAuthorized) { _, newValue in
      if newValue {
        showIntroScreen = false
      }
      refreshAlerts()
    }
    .onChange(of: profiles) { oldValue, newValue in
      if !newValue.isEmpty {
        loadApp()
      }
      refreshAlerts()
    }
    .onChange(of: scenePhase) { oldPhase, newPhase in
      if newPhase == .active {
        requestAuthorizer.refreshAuthorizationStatus()
        loadApp()
        refreshAlerts()
        FeastNotificationScheduler().reschedule()
      } else if newPhase == .background {
        unloadApp()
      }
    }
    .onChange(of: isBlocking) { _, newValue in
      if !newValue {
        showActiveProfileSessionView = false
      }
      // Session start/stop clears timer notifications — put the 6:00
      // feast notices back afterwards.
      FeastNotificationScheduler().reschedule()
    }
    .onReceive(strategyManager.$errorMessage) { errorMessage in
      guard let message = errorMessage, !showActiveProfileSessionView else { return }
      showErrorAlert(message: message)
    }
    .onAppear {
      onAppearApp()
    }
  }

}

#Preview {
  HomeView()
    .environmentObject(RequestAuthorizer())
    .environmentObject(TipManager())
    .environmentObject(AlertsManager())
    .environmentObject(NavigationManager())
    .environmentObject(StrategyManager())
    .defaultAppStorage(UserDefaults(suiteName: "preview")!)
    .onAppear {
      UserDefaults(suiteName: "preview")!.set(
        false,
        forKey: "showIntroScreen"
      )
    }
}
