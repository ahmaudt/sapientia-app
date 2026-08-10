import SwiftUI
import UIKit

/// The docked running-session bar (screen 14). A blueprint bar — hairline
/// top rule, name + state on the left, the session clock in Barlow
/// Condensed on the right — no gradient, glass, or shadow.
struct HomeProfileLauncher: View {
  let activeProfile: BlockedProfiles?
  let displayTime: TimeInterval
  var isBreakActive = false
  var isPauseActive = false
  let onStartTapped: () -> Void
  var onActiveTapped: () -> Void = {}

  var body: some View {
    Group {
      if let activeProfile {
        activeBar(activeProfile)
      } else {
        Button("New session") { startTapped() }
          .buttonStyle(BlueprintPrimaryButtonStyle())
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, SapientiaTheme.space2)
  }

  private func activeBar(_ profile: BlockedProfiles) -> some View {
    Button(action: activeTapped) {
      HStack(alignment: .center, spacing: SapientiaTheme.space4) {
        VStack(alignment: .leading, spacing: 2) {
          Text(profile.name)
            .font(.sapientiaHeading(20))
            .foregroundColor(SapientiaTheme.text)
            .lineLimit(1)
          Text(stateLabel)
            .font(.sapientiaBody(13))
            .foregroundColor(SapientiaTheme.text.opacity(0.55))
        }
        Spacer(minLength: SapientiaTheme.space3)
        Text(DateFormatters.formatDurationClock(displayTime))
          .font(.sapientiaHeading(30))
          .foregroundColor(SapientiaTheme.accent700)
          .contentTransition(.numericText())
          .animation(.default, value: displayTime)
          .lineLimit(1)
          .minimumScaleFactor(0.7)
      }
      .padding(.horizontal, SapientiaTheme.space4)
      .padding(.vertical, SapientiaTheme.space3)
      .frame(maxWidth: .infinity)
      .background(SapientiaTheme.background)
      .overlay(alignment: .top) {
        Rectangle().fill(SapientiaTheme.divider).frame(height: 1)
      }
      .overlay(alignment: .bottom) {
        Rectangle().fill(SapientiaTheme.divider).frame(height: 1)
      }
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .accessibilityLabel(accessibilityLabel(for: profile))
  }

  private var stateLabel: String {
    if isPauseActive { return "Paused" }
    if isBreakActive { return "On break" }
    return "Held — tap to view"
  }

  private func startTapped() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    onStartTapped()
  }

  private func activeTapped() {
    UIImpactFeedbackGenerator(style: .light).impactOccurred()
    onActiveTapped()
  }

  private func accessibilityLabel(for profile: BlockedProfiles) -> String {
    if isPauseActive { return "Paused rule \(profile.name)" }
    if isBreakActive { return "On break, rule \(profile.name)" }
    return "Active rule \(profile.name)"
  }
}

#Preview("Active") {
  VStack {
    Spacer()
    HomeProfileLauncher(
      activeProfile: BlockedProfiles(name: "Deep Work"),
      displayTime: 3665,
      onStartTapped: {},
      onActiveTapped: {}
    )
  }
  .background(SapientiaTheme.background)
}
