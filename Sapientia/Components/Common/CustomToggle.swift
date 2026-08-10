import SwiftUI

/// A blueprint toggle row: title + muted description on the left, a squared
/// switch on the right, a bottom hairline. Reads as a ruled row, not a
/// grouped-list cell.
struct CustomToggle: View {
  let title: String
  let description: String
  @Binding var isOn: Bool
  var isDisabled: Bool = false
  var errorMessage: String? = nil
  var showsDivider: Bool = true

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      Toggle(isOn: $isOn) {
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.sapientiaBody(17))
            .foregroundColor(SapientiaTheme.text)
          Text(description)
            .font(.sapientiaBody(13))
            .foregroundColor(SapientiaTheme.text.opacity(0.55))
            .fixedSize(horizontal: false, vertical: true)
          if isDisabled, let errorMessage {
            Text(errorMessage)
              .font(.sapientiaBody(13))
              .foregroundColor(SapientiaTheme.accent700)
          }
        }
      }
      .toggleStyle(BlueprintToggleStyle())
      .disabled(isDisabled)
      .opacity(isDisabled ? 0.5 : 1)
      .padding(.vertical, SapientiaTheme.space4)

      if showsDivider {
        Rectangle().fill(SapientiaTheme.divider).frame(height: 1)
      }
    }
  }
}

#Preview {
  VStack(alignment: .leading, spacing: 0) {
    CustomToggle(
      title: "Strict mode",
      description: "The app cannot be deleted or the rule edited mid-session.",
      isOn: .constant(true)
    )
    CustomToggle(
      title: "Pray before unblocking",
      description: "The Collect of the day stands in front of the tag.",
      isOn: .constant(false)
    )
    CustomToggle(
      title: "Disabled",
      description: "This toggle is currently disabled.",
      isOn: .constant(false),
      isDisabled: true
    )
  }
  .padding()
  .background(SapientiaTheme.background)
}
