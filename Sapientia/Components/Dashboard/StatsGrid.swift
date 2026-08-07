import SwiftUI

/// Home screen stat tiles: time kept this week and emergency unblocks
/// remaining, in a hairline-divided two-column grid. Tapping the kept-time
/// tile opens insights (wired by HomeView).
struct StatsGrid: View {
  let keptThisWeek: TimeInterval
  let emergencyUnblocksRemaining: Int
  let onInsightsTapped: (() -> Void)?

  var body: some View {
    HStack(spacing: 1) {
      tile(
        value: HomeStats.keptTimeString(keptThisWeek),
        label: "Kept this week",
        action: onInsightsTapped
      )
      tile(
        value: "\(emergencyUnblocksRemaining)",
        label: "Emergency unblocks left",
        action: nil
      )
    }
    .background(SapientiaTheme.divider)
    .border(SapientiaTheme.divider, width: 1)
    .fixedSize(horizontal: false, vertical: true)
  }

  private func tile(
    value: String, label: String, action: (() -> Void)?
  ) -> some View {
    Button {
      action?()
    } label: {
      VStack(alignment: .leading, spacing: 2) {
        Text(value)
          .font(.sapientiaHeading(30))
          .foregroundColor(SapientiaTheme.text)
        Text(label)
          .font(.sapientiaHeading(12))
          .kerning(1.0)
          .textCase(.uppercase)
          .foregroundColor(SapientiaTheme.text.opacity(0.55))
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .padding(.vertical, SapientiaTheme.space3)
      .padding(.horizontal, SapientiaTheme.space4)
      .background(SapientiaTheme.background)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(action == nil)
  }
}

#Preview {
  StatsGrid(
    keptThisWeek: 12 * 3600 + 40 * 60,
    emergencyUnblocksRemaining: 2,
    onInsightsTapped: {}
  )
  .padding()
}
