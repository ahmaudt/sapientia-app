import SwiftUI

/// Empty-state invitation to create the first rule, in the blueprint style.
struct Welcome: View {
  @EnvironmentObject var themeManager: ThemeManager
  let onGuidedTap: () -> Void
  let onAdvancedTap: () -> Void

  var body: some View {
    BlueprintCard(padding: 0) {
      VStack(alignment: .leading, spacing: 0) {
        Text("Your first rule")
          .font(.sapientiaHeading(12))
          .kerning(1.2)
          .textCase(.uppercase)
          .foregroundColor(SapientiaTheme.accent)

        Text("Choose what to set aside")
          .font(.sapientiaHeading(30))
          .foregroundColor(SapientiaTheme.text)
          .padding(.top, SapientiaTheme.space2)

        Text(
          "Group the apps and websites that scatter you, pair a tag or a code, and let the session open and close by touch."
        )
        .font(.sapientiaBody(15))
        .lineSpacing(4)
        .foregroundColor(SapientiaTheme.text.opacity(0.62))
        .padding(.top, SapientiaTheme.space3)

        Button("Create a rule") {
          onGuidedTap()
        }
        .buttonStyle(BlueprintPrimaryButtonStyle())
        .padding(.top, SapientiaTheme.space6)

        Button(action: onAdvancedTap) {
          Text("Use the full editor")
            .font(.sapientiaBody(14))
            .foregroundColor(SapientiaTheme.accent700)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .padding(.top, SapientiaTheme.space4)
      }
      .padding(.vertical, SapientiaTheme.space6)
      .padding(.horizontal, SapientiaTheme.space4)
    }
  }
}

#Preview {
  ZStack {
    SapientiaTheme.background.ignoresSafeArea()

    Welcome(
      onGuidedTap: { print("Guided tapped") },
      onAdvancedTap: { print("Advanced tapped") }
    )
    .padding(.horizontal)
    .environmentObject(ThemeManager.shared)
  }
}
