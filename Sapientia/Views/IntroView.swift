import SwiftUI

struct IntroView: View {
  let onRequestAuthorization: () -> Void

  var body: some View {
    SapientiaIntroView(
      onRequestAuthorization: onRequestAuthorization
    )
  }
}

#Preview {
  IntroView {
    print("Request authorization tapped")
  }
  .environmentObject(ThemeManager.shared)
}
