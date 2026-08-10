import FamilyControls
import SwiftUI

/// Screen 08 — Set aside. A BlueprintStage that FRAMES Apple's Screen Time
/// picker (which renders itself and takes no styling): a count grid, a
/// privacy note, and the system picker filling the rest.
///
/// The 1s timer + `refreshID` reset are a deliberate workaround for an iOS
/// bug where `FamilyActivityPicker` stops reflecting selection changes; they
/// MUST stay. The Refresh affordance is the stage's trailing-adjacent action.
struct AppPicker: View {
  let stateUpdateTimer = Timer.publish(every: 1, on: .main, in: .common)
    .autoconnect()

  @Binding var selection: FamilyActivitySelection
  @Binding var isPresented: Bool

  var allowMode: Bool = false

  @State private var updateFlag: Bool = false
  @State private var refreshID: UUID = UUID()
  @State private var showLimitInfo: Bool = false
  @State private var showLimitAlert: Bool = false

  private var appCount: Int { selection.applicationTokens.count }
  private var categoryCount: Int { selection.categoryTokens.count }
  private var selectedCount: Int {
    FamilyActivityUtil.countSelectedActivities(selection, allowMode: allowMode)
  }
  private var isOverLimit: Bool { selectedCount > 50 }

  private func handleDone() {
    if isOverLimit { showLimitAlert = true } else { isPresented = false }
  }

  var body: some View {
    BlueprintStage(
      title: allowMode ? "Set apart" : "Set aside",
      leadingLabel: "Cancel",
      leadingAction: { isPresented = false },
      trailingLabel: "Done",
      trailingAction: { handleDone() },
      scrolls: false
    ) {
      VStack(alignment: .leading, spacing: 0) {
        BlueprintStatGrid(cells: [
          BlueprintStatCell(value: "\(appCount)", label: "Apps", action: nil),
          BlueprintStatCell(value: "\(categoryCount)", label: "Categories", action: nil),
        ])
        .padding(.horizontal, SapientiaTheme.space6)
        .padding(.top, SapientiaTheme.space6)

        HStack {
          Text("Chosen through Apple's own picker. Sapientia never sees which apps you named — only how many.")
            .font(.sapientiaBody(13))
            .foregroundColor(SapientiaTheme.text.opacity(0.55))
          Spacer(minLength: SapientiaTheme.space3)
          Button("Refresh") { refreshID = UUID() }
            .font(.sapientiaHeading(13))
            .kerning(1.0)
            .textCase(.uppercase)
            .foregroundColor(SapientiaTheme.accent700)
            .buttonStyle(.plain)
        }
        .padding(.horizontal, SapientiaTheme.space6)
        .padding(.vertical, SapientiaTheme.space4)

        // System picker — framed, not restyled.
        ZStack {
          Text(verbatim: "Updating view state because of bug in iOS...")
            .foregroundStyle(.clear)
            .accessibilityHidden(true)
            .opacity(updateFlag ? 1 : 0)
          FamilyActivityPicker(selection: $selection)
            .id(refreshID)
        }
        .tint(SapientiaTheme.accent)
        .onReceive(stateUpdateTimer) { _ in updateFlag.toggle() }
      }
    }
    .alert("Apple's 50-App Limit", isPresented: $showLimitInfo) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(
        allowMode
          ? "Apps inside selected categories each count toward Apple's 50-app limit."
          : "Select up to 50 apps or categories. Each category counts as one item.")
    }
    .alert("Over 50 App Limit", isPresented: $showLimitAlert) {
      Button("Cancel", role: .cancel) {}
      Button("OK") { isPresented = false }
    } message: {
      Text(
        "You have selected more than 50 apps and sites. This can lead to issues due to Apple's hard limit of 50.")
    }
  }
}

#if DEBUG
  struct AppPicker_Previews: PreviewProvider {
    static var previews: some View {
      AppPicker(
        selection: .constant(FamilyActivitySelection()),
        isPresented: .constant(true)
      )
    }
  }
#endif
