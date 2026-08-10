import XCTest

@testable import sapientia

final class BlueprintStatGridTests: XCTestCase {

  func testStatsGridMapsTwoCells() {
    let grid = StatsGrid(
      keptThisWeek: 12 * 3600 + 40 * 60,
      emergencyUnblocksRemaining: 2,
      onInsightsTapped: {}
    )
    let cells = grid.cells
    XCTAssertEqual(cells.count, 2)
    XCTAssertEqual(cells[0].value, "12h 40m")
    XCTAssertEqual(cells[0].label, "Kept this week")
    XCTAssertEqual(cells[1].value, "2")
    XCTAssertEqual(cells[1].label, "Emergency unblocks left")
  }

  func testKeptTileIsTappableAndEmergencyTileIsNot() {
    let grid = StatsGrid(
      keptThisWeek: 0,
      emergencyUnblocksRemaining: 0,
      onInsightsTapped: {}
    )
    XCTAssertNotNil(grid.cells[0].action, "kept-time tile should open insights")
    XCTAssertNil(grid.cells[1].action, "emergency tile has no tap")
  }

  func testNoInsightsHandlerLeavesKeptTileInert() {
    let grid = StatsGrid(
      keptThisWeek: 3600, emergencyUnblocksRemaining: 1, onInsightsTapped: nil)
    XCTAssertNil(grid.cells[0].action)
  }

  func testBlueprintStatGridAcceptsThreeCells() {
    // Screen 08 uses a 2-cell count grid; records screens use 2–3. Ensure
    // the grid itself is not hardwired to two.
    let cells = [
      BlueprintStatCell(value: "14", label: "Apps", action: nil),
      BlueprintStatCell(value: "3", label: "Categories", action: nil),
      BlueprintStatCell(value: "6", label: "Domains", action: nil),
    ]
    let grid = BlueprintStatGrid(cells: cells)
    XCTAssertEqual(grid.cells.count, 3)
  }
}
