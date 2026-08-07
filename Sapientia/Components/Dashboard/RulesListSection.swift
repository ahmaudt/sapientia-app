import SwiftUI

/// Home screen "Your rules" list: hairline-divided rows with a Start (or
/// Stop) action per profile. Preserves all actions the old profile list
/// offered: start, stop, edit, stats, manage.
struct RulesListSection: View {
  let profiles: [BlockedProfiles]
  let isBlocking: Bool
  let activeSessionProfileId: UUID?
  let onStartTapped: (BlockedProfiles) -> Void
  let onStopTapped: (BlockedProfiles) -> Void
  let onEditTapped: (BlockedProfiles) -> Void
  let onStatsTapped: (BlockedProfiles) -> Void
  let onManageTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        Text("Your rules")
          .sapientiaKicker()
        Spacer()
        Button {
          onManageTapped()
        } label: {
          Text("Manage")
            .font(.sapientiaHeading(13))
            .kerning(1.0)
            .textCase(.uppercase)
            .foregroundColor(SapientiaTheme.accent700)
        }
        .buttonStyle(.plain)
      }
      .padding(.bottom, SapientiaTheme.space3)

      Rectangle()
        .fill(SapientiaTheme.divider)
        .frame(height: 1)

      ForEach(profiles) { profile in
        let isActive = profile.id == activeSessionProfileId
        HStack(alignment: .center) {
          VStack(alignment: .leading, spacing: 2) {
            Text(profile.name)
              .font(.sapientiaHeading(20))
              .foregroundColor(SapientiaTheme.text)
            Text(meta(for: profile))
              .font(.sapientiaBody(13))
              .foregroundColor(SapientiaTheme.text.opacity(0.55))
          }
          .contentShape(Rectangle())
          .onTapGesture { onEditTapped(profile) }

          Spacer()

          Button(isActive ? "Stop" : "Start") {
            isActive ? onStopTapped(profile) : onStartTapped(profile)
          }
          .buttonStyle(
            BlueprintSecondaryButtonStyle(
              fontSize: 14,
              foreground: isActive ? SapientiaTheme.background : SapientiaTheme.accent700)
          )
          .background(isActive ? SapientiaTheme.accent : Color.clear)
          .textCase(.uppercase)
          .disabled(!isActive && isBlocking)
          .opacity(!isActive && isBlocking ? 0.4 : 1)
        }
        .padding(.vertical, SapientiaTheme.space4)
        .contextMenu {
          Button("Edit") { onEditTapped(profile) }
          Button("Insights") { onStatsTapped(profile) }
        }

        Rectangle()
          .fill(SapientiaTheme.divider)
          .frame(height: 1)
      }
    }
  }

  private func meta(for profile: BlockedProfiles) -> String {
    RuleRowMeta.metaString(
      appCount: profile.selectedActivity.applicationTokens.count,
      categoryCount: profile.selectedActivity.categoryTokens.count,
      strategyId: profile.blockingStrategyId,
      isStrict: profile.enableStrictMode,
      scheduleText: scheduleText(for: profile)
    )
  }

  private func scheduleText(for profile: BlockedProfiles) -> String? {
    guard let schedule = profile.schedule else { return nil }
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm"
    var startComponents = DateComponents()
    startComponents.hour = schedule.startHour
    startComponents.minute = schedule.startMinute
    var endComponents = DateComponents()
    endComponents.hour = schedule.endHour
    endComponents.minute = schedule.endMinute
    let calendar = Calendar.current
    guard
      let start = calendar.date(from: startComponents),
      let end = calendar.date(from: endComponents)
    else { return nil }
    return "\(formatter.string(from: start))–\(formatter.string(from: end))"
  }
}
