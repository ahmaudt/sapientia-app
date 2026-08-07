import SwiftUI

/// The Home screen's scrollable content (screen 02): date header, alerts,
/// feast card, rules list, stats grid, and the New-session CTA. Pure
/// presentation — all behavior arrives through `HomeScreenActions`.
struct HomeScreenActions {
  let onSettings: () -> Void
  let onAlertTapped: (HomeAlert) -> Void
  let onGuidedCreate: () -> Void
  let onAdvancedCreate: () -> Void
  let onStart: (BlockedProfiles) -> Void
  let onStop: (BlockedProfiles) -> Void
  let onEdit: (BlockedProfiles) -> Void
  let onStats: (BlockedProfiles) -> Void
  let onManage: () -> Void
  let onInsights: (BlockedProfiles) -> Void
  let onNewSession: () -> Void
}

struct HomeScreenContent: View {
  let profiles: [BlockedProfiles]
  let recentCompletedSessions: [BlockedProfileSession]
  let alerts: [HomeAlert]
  let isBlocking: Bool
  let activeSessionProfileId: UUID?
  let emergencyUnblocksRemaining: Int
  let actions: HomeScreenActions

  private var liturgicalDay: LiturgicalDay {
    OrdinariateCalendar().day(for: Date())
  }

  private var dateHeading: String {
    let formatter = DateFormatter()
    formatter.dateFormat = "EEEE · d MMMM"
    return formatter.string(from: Date())
  }

  private var keptThisWeek: TimeInterval {
    let weekStart = WeeklySessionAggregator.startOfWeek(for: Date())
    let intervals = recentCompletedSessions.compactMap { session -> WeeklySessionInterval? in
      guard let endTime = session.endTime else { return nil }
      return WeeklySessionInterval(startTime: session.startTime, endTime: endTime)
    }
    return WeeklySessionAggregator.aggregate(
      sessions: intervals, weekStart: weekStart
    ).totalFocusTime
  }

  private var mostRecentProfile: BlockedProfiles? {
    let latestSessionProfileId = recentCompletedSessions.first?.blockedProfile.id
    return profiles.first { $0.id == latestSessionProfileId } ?? profiles.first
  }

  var body: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: SapientiaTheme.space8) {
        header

        HomeAlertsView(alerts: alerts, onAlertTapped: actions.onAlertTapped)
          .padding(.horizontal, 16)

        FeastCard(day: liturgicalDay)
          .padding(.horizontal, 16)

        if profiles.isEmpty {
          Welcome(
            onGuidedTap: actions.onGuidedCreate,
            onAdvancedTap: actions.onAdvancedCreate
          )
          .padding(.horizontal, 16)
        } else {
          rulesAndStats
        }
      }
    }
    .background(SapientiaTheme.background.ignoresSafeArea())
  }

  private var header: some View {
    HStack(alignment: .center) {
      Text(dateHeading)
        .sapientiaKicker()
      Spacer()
      Button {
        actions.onSettings()
      } label: {
        Image(systemName: "slider.horizontal.3")
          .font(.system(size: 17, weight: .regular))
          .foregroundColor(SapientiaTheme.accent700)
          .frame(width: 36, height: 36)
          .border(SapientiaTheme.divider, width: 1)
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Settings")
    }
    .padding(.horizontal, 16)
    .padding(.top, 16)
  }

  @ViewBuilder
  private var rulesAndStats: some View {
    RulesListSection(
      profiles: profiles,
      isBlocking: isBlocking,
      activeSessionProfileId: activeSessionProfileId,
      onStartTapped: actions.onStart,
      onStopTapped: actions.onStop,
      onEditTapped: actions.onEdit,
      onStatsTapped: actions.onStats,
      onManageTapped: actions.onManage
    )
    .padding(.horizontal, 16)

    StatsGrid(
      keptThisWeek: keptThisWeek,
      emergencyUnblocksRemaining: emergencyUnblocksRemaining,
      onInsightsTapped: mostRecentProfile.map { profile in
        { actions.onInsights(profile) }
      }
    )
    .padding(.horizontal, 16)

    if !isBlocking {
      Button("New session") {
        actions.onNewSession()
      }
      .buttonStyle(BlueprintPrimaryButtonStyle())
      .padding(.horizontal, 16)
      .padding(.bottom, SapientiaTheme.space4)
    }
  }
}
