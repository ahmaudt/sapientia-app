import FamilyControls
import SwiftUI

/// The "Apps & categories" row in the rule editor (flow 07): a blueprint row
/// showing the current count with an Edit action that opens the Screen Time
/// picker stage.
struct BlockedProfileAppSelector: View {
  var selection: FamilyActivitySelection
  var buttonAction: () -> Void
  var allowMode: Bool = false
  var disabled: Bool = false
  var disabledText: String?

  private var catAndAppCount: Int {
    FamilyActivityUtil.countSelectedActivities(selection, allowMode: allowMode)
  }
  private var countDisplayText: String {
    FamilyActivityUtil.getCountDisplayText(selection, allowMode: allowMode)
  }
  private var shouldShowWarning: Bool {
    FamilyActivityUtil.shouldShowAllowModeWarning(selection, allowMode: allowMode)
  }

  var body: some View {
    BlueprintListRow(
      title: allowMode ? "Apps to allow" : "Apps & categories",
      caption: catAndAppCount == 0 ? "None chosen" : "\(countDisplayText)",
      onTap: disabled ? nil : buttonAction
    ) {
      if !disabled {
        BlueprintRowAction(label: catAndAppCount == 0 ? "Choose" : "Edit", action: buttonAction)
      }
    }

    if let disabledText, disabled {
      Text(disabledText)
        .font(.sapientiaBody(13))
        .foregroundColor(SapientiaTheme.accent700)
        .padding(.top, 4)
    } else if shouldShowWarning {
      Text("Selected categories expand to individual apps. Apple's 50-app limit applies.")
        .font(.sapientiaBody(13))
        .foregroundColor(SapientiaTheme.text.opacity(0.55))
        .padding(.top, 4)
    }
  }
}

#Preview {
  VStack(spacing: 0) {
    BlockedProfileAppSelector(selection: FamilyActivitySelection(), buttonAction: {})
  }
  .padding()
  .background(SapientiaTheme.background)
}
