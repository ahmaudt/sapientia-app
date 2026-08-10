import SwiftUI

/// Home screen stat tiles: time kept this week and emergency unblocks
/// remaining, on the shared `BlueprintStatGrid`. Tapping the kept-time tile
/// opens insights (wired by HomeView); the emergency tile is inert.
struct StatsGrid: View {
  let keptThisWeek: TimeInterval
  let emergencyUnblocksRemaining: Int
  let onInsightsTapped: (() -> Void)?

  var cells: [BlueprintStatCell] {
    [
      BlueprintStatCell(
        value: HomeStats.keptTimeString(keptThisWeek),
        label: "Kept this week",
        action: onInsightsTapped
      ),
      BlueprintStatCell(
        value: "\(emergencyUnblocksRemaining)",
        label: "Emergency unblocks left",
        action: nil
      ),
    ]
  }

  var body: some View {
    BlueprintStatGrid(cells: cells)
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
