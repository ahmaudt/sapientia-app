import SwiftUI

struct AppIconPicker: View {
  let selectionColor: Color

  @State private var selectedIconName = UIApplication.shared.alternateIconName
  @State private var isChangingIcon = false
  @State private var showError = false
  @State private var errorMessage = ""

  private let columns = Array(
    repeating: GridItem(.flexible(), spacing: 12),
    count: 3
  )

  var body: some View {
    BlueprintFormSection(title: "App icon") {
      LazyVGrid(columns: columns, spacing: 12) {
        ForEach(AppIconOption.allCases) { icon in
          Button {
            select(icon)
          } label: {
            VStack(spacing: 8) {
              icon.preview
                .frame(width: 64, height: 64)
                .overlay {
                  Rectangle()
                    .stroke(
                      isSelected(icon) ? selectionColor : SapientiaTheme.divider,
                      lineWidth: isSelected(icon) ? 2 : 1
                    )
                }

              Text(icon.displayName)
                .font(.caption)
                .foregroundColor(SapientiaTheme.text)
                .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
          }
          .buttonStyle(.plain)
          .disabled(isChangingIcon || isSelected(icon))
          .accessibilityLabel("Use the \(icon.displayName) app icon")
          .accessibilityAddTraits(isSelected(icon) ? .isSelected : [])
        }
      }
      .padding(.vertical, 8)

      if !UIApplication.shared.supportsAlternateIcons {
        Text("Alternate app icons are not available on this device.")
          .font(.caption)
          .foregroundColor(SapientiaTheme.text.opacity(0.55))
      }
    }
    .alert("Unable to Change App Icon", isPresented: $showError) {
      Button("OK") {}
    } message: {
      Text(errorMessage)
    }
    .onAppear {
      selectedIconName = UIApplication.shared.alternateIconName
    }
  }

  private func isSelected(_ icon: AppIconOption) -> Bool {
    selectedIconName == icon.alternateIconName
  }

  private func select(_ icon: AppIconOption) {
    guard UIApplication.shared.supportsAlternateIcons else {
      errorMessage = "Alternate app icons are not available on this device."
      showError = true
      return
    }

    isChangingIcon = true
    UIApplication.shared.setAlternateIconName(icon.alternateIconName) { error in
      Task { @MainActor in
        isChangingIcon = false

        if let error {
          errorMessage = error.localizedDescription
          showError = true
          selectedIconName = UIApplication.shared.alternateIconName
          return
        }

        selectedIconName = UIApplication.shared.alternateIconName
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
      }
    }
  }
}

private enum AppIconOption: String, CaseIterable, Identifiable {
  case steel
  case paper
  case accent

  var id: String { rawValue }

  var displayName: String {
    switch self {
    case .steel: "Steel"
    case .paper: "Paper"
    case .accent: "Accent"
    }
  }

  /// nil = the primary (default) app icon.
  var alternateIconName: String? {
    switch self {
    case .steel: nil
    case .paper: "AppIcon-Paper"
    case .accent: "AppIcon-Accent"
    }
  }

  /// Live vector preview of the mark on its field.
  @ViewBuilder var preview: some View {
    switch self {
    case .steel:
      SapientiaMark.steel(showLetters: false)
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SapientiaTheme.accent900)
    case .paper:
      SapientiaMark.paper(showLetters: false)
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(SapientiaTheme.paper)
    case .accent:
      SapientiaMark(
        ringColor: SapientiaTheme.paper,
        crossColor: SapientiaTheme.accent900,
        letterColor: SapientiaTheme.paper,
        showLetters: false
      )
      .padding(14)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
      .background(SapientiaTheme.accent)
    }
  }
}

#Preview {
  Form {
    AppIconPicker(selectionColor: SapientiaTheme.accent)
  }
}
