import FamilyControls
import SwiftUI
import UIKit

/// Screen 13 — the running session. Light/paper (a session you glance at
/// twenty times a day is not a rite): the clock in Barlow Condensed, one
/// fixed sentence, blueprint stat cells, and blueprint actions.
struct ActiveProfileSessionView: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var strategyManager: StrategyManager

  let profile: BlockedProfiles
  let elapsedTime: TimeInterval
  let displayTime: TimeInterval
  let isBreakAvailable: Bool
  let isBreakActive: Bool
  let isPauseActive: Bool
  let onBreakTapped: () -> Void
  let onStopTapped: () -> Void

  @State private var showEmergencyView = false
  @State private var showProfileInsights = false
  @State private var showingAlert = false
  @State private var alertMessage = ""

  private var showStopButton: Bool { profile.showStopButton(elapsedTime: elapsedTime) }
  private var stopButtonAction: BlockingStrategySessionAction {
    blockingStrategy?.activeSessionAction(isPauseActive: isPauseActive) ?? .stop()
  }
  private var blockingStrategy: BlockingStrategy? {
    guard let id = profile.blockingStrategyId else { return nil }
    return StrategyManager.getStrategyFromId(id: id)
  }
  private var strategyName: String { blockingStrategy?.name ?? "Manual" }

  private var isSoftUnblockStrategy: Bool {
    guard let id = profile.blockingStrategyId else { return false }
    return [NFCSoftUnblockBlockingStrategy.id, QRSoftUnblockBlockingStrategy.id].contains(id)
  }

  private var appCount: Int { profile.selectedActivity.applicationTokens.count }

  private var unblockEnding: String {
    let items = profile.physicalUnblockItems ?? []
    if items.contains(where: { $0.type == .nfc }) { return "tap your tag" }
    if items.contains(where: { $0.type == .qrCode }) { return "scan your code" }
    if strategyName.contains("Timer") { return "the timer lifts it" }
    return "you end it"
  }

  private var fixedSentence: String {
    let apps = appCount == 1 ? "1 app is" : "\(appCount) apps are"
    return "\(apps) set aside. Nothing is asked of you until you \(unblockEnding)."
  }

  private var stateLabel: String {
    if isPauseActive { return "Paused" }
    if isBreakActive { return "On break" }
    return "Held"
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      header

      ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: SapientiaTheme.space6) {
          timerBlock
          statGrid
          if isSoftUnblockStrategy {
            SoftUnblockActiveGrantsCard(profileId: profile.id)
          }
        }
        .padding(.top, SapientiaTheme.space8)
      }

      actions
    }
    .padding(.horizontal, 24)
    .padding(.top, SapientiaTheme.space4)
    .padding(.bottom, SapientiaTheme.space6)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .background(SapientiaTheme.background.ignoresSafeArea())
    .sheet(isPresented: $showEmergencyView) {
      EmergencyView().presentationDetents([.height(350), .large])
    }
    .sheet(isPresented: $showProfileInsights) {
      ProfileInsightsView(profile: profile)
    }
    .sheet(isPresented: $strategyManager.showCustomStrategyView) {
      BlockingStrategyActionView(
        customView: strategyManager.customStrategyView,
        presentationDetents: strategyManager.customStrategyViewPresentationDetents
      )
    }
    .onReceive(strategyManager.$errorMessage) { errorMessage in
      guard let message = errorMessage else { return }
      alertMessage = message
      showingAlert = true
    }
    .alert("Whoops", isPresented: $showingAlert) {
      Button("OK", role: .cancel) { dismissAlert() }
    } message: {
      Text(alertMessage)
    }
  }

  private var header: some View {
    HStack(alignment: .center) {
      Text(stateLabel).sapientiaKicker()
      Spacer()
      iconButton("chart.line.uptrend.xyaxis", "Insights") { showProfileInsights = true }
      iconButton("xmark", "Close") { dismiss() }
    }
    .padding(.bottom, SapientiaTheme.space4)
    .overlay(alignment: .bottom) {
      Rectangle().fill(SapientiaTheme.divider).frame(height: 1)
    }
  }

  private func iconButton(_ system: String, _ label: String, action: @escaping () -> Void)
    -> some View
  {
    Button(action: action) {
      Image(systemName: system)
        .font(.system(size: 15, weight: .regular))
        .foregroundColor(SapientiaTheme.accent700)
        .frame(width: 36, height: 36)
        .border(SapientiaTheme.divider, width: 1)
    }
    .buttonStyle(.plain)
    .accessibilityLabel(label)
  }

  private var timerBlock: some View {
    VStack(alignment: .leading, spacing: SapientiaTheme.space2) {
      Text("\(profile.name) · \(strategyName)")
        .font(.sapientiaBody(15))
        .foregroundColor(SapientiaTheme.text.opacity(0.55))

      Text(DateFormatters.formatDurationClock(displayTime))
        .font(.sapientiaHeading(58))
        .foregroundColor(SapientiaTheme.text)
        .contentTransition(.numericText())
        .animation(.default, value: displayTime)
        .lineLimit(1)
        .minimumScaleFactor(0.6)

      Text(fixedSentence)
        .font(.sapientiaBody(15))
        .lineSpacing(3)
        .foregroundColor(SapientiaTheme.text.opacity(0.62))
        .padding(.top, SapientiaTheme.space2)
    }
  }

  private var statGrid: some View {
    var cells: [BlueprintStatCell] = [
      BlueprintStatCell(value: "\(appCount)", label: "Apps", action: nil)
    ]
    if profile.enableBreaks {
      cells.append(
        BlueprintStatCell(value: "\(profile.breakTimeInMinutes)m", label: "Break", action: nil))
    }
    if profile.enableEmergencyUnblock {
      cells.append(
        BlueprintStatCell(
          value: "\(strategyManager.getRemainingEmergencyUnblocks())",
          label: "Emergencies", action: nil))
    }
    return BlueprintStatGrid(cells: cells)
  }

  private var actions: some View {
    VStack(spacing: SapientiaTheme.space3) {
      if showStopButton {
        Button(stopEndTitle) { triggerStop() }
          .buttonStyle(BlueprintPrimaryButtonStyle())
      }

      if !isPauseActive && isBreakAvailable {
        BlueprintHoldButton(
          title: isBreakActive ? "Hold to end break" : "Hold to take a break",
          action: onBreakTapped
        )
      }

      if profile.enableEmergencyUnblock {
        Button("Emergency access") { showEmergencyView = true }
          .font(.sapientiaBody(15))
          .foregroundColor(SapientiaTheme.accent700)
          .padding(.top, SapientiaTheme.space1)
      }
    }
  }

  private var stopEndTitle: String {
    switch unblockEnding {
    case "tap your tag": return "End — tap your tag"
    case "scan your code": return "End — scan your code"
    default: return stopButtonAction.title
    }
  }

  private func triggerStop() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    onStopTapped()
  }

  private func dismissAlert() {
    showingAlert = false
    strategyManager.errorMessage = nil
  }
}

// MARK: - Soft-unblock active grants (blueprint)

private struct SoftUnblockActiveGrantsCard: View {
  private static let visibleGrantLimit = 3
  let profileId: UUID

  var body: some View {
    TimelineView(.periodic(from: .now, by: 1)) { timeline in
      let activeGrants = SoftUnblockGrantStore.activeGrants(for: profileId, at: timeline.date)
        .sorted { lhs, rhs in
          lhs.expiresAt == rhs.expiresAt
            ? lhs.createdAt < rhs.createdAt : lhs.expiresAt < rhs.expiresAt
        }
      let visibleGrants = Array(activeGrants.prefix(Self.visibleGrantLimit))
      let overflowCount = activeGrants.count - visibleGrants.count

      if !activeGrants.isEmpty {
        BlueprintCard(padding: 0) {
          VStack(spacing: 0) {
            SectionHeaderLabel(title: "Open now")
              .padding(.bottom, SapientiaTheme.space2)
            ForEach(Array(visibleGrants.enumerated()), id: \.element.id) { _, grant in
              SoftUnblockActiveGrantRow(grant: grant, date: timeline.date)
              Rectangle().fill(SapientiaTheme.divider).frame(height: 1)
            }
            if overflowCount > 0 {
              Text("+\(overflowCount) more open")
                .font(.sapientiaBody(13))
                .foregroundColor(SapientiaTheme.text.opacity(0.55))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, SapientiaTheme.space3)
            }
          }
          .padding(SapientiaTheme.space4)
        }
      }
    }
  }
}

private struct SoftUnblockActiveGrantRow: View {
  let grant: SoftUnblockGrant
  let date: Date

  private var remainingSeconds: Int {
    max(Int(ceil(grant.expiresAt.timeIntervalSince(date))), 0)
  }
  private var countdownText: String {
    String(format: "%02d:%02d", remainingSeconds / 60, remainingSeconds % 60)
  }

  var body: some View {
    HStack(spacing: SapientiaTheme.space3) {
      resourceLabel
        .font(.sapientiaBody(15))
        .foregroundColor(SapientiaTheme.text)
        .lineLimit(1)
      Spacer(minLength: SapientiaTheme.space2)
      Text(countdownText)
        .font(.sapientiaHeading(17))
        .foregroundColor(SapientiaTheme.accent700)
        .contentTransition(.numericText(countsDown: true))
    }
    .padding(.vertical, SapientiaTheme.space3)
  }

  @ViewBuilder private var resourceLabel: some View {
    switch grant.resource {
    case .application(let token): Label(token)
    case .category(let token): Label(token)
    }
  }
}

#Preview {
  ActiveProfileSessionView(
    profile: BlockedProfiles(name: "Deep Work"),
    elapsedTime: 3665,
    displayTime: 3665,
    isBreakAvailable: true,
    isBreakActive: false,
    isPauseActive: false,
    onBreakTapped: {},
    onStopTapped: {}
  )
  .environmentObject(StrategyManager())
}
