import SwiftUI

struct IntroStep {
  let number: String
  let title: String
  let detail: String
}

final class IntroViewModel: ObservableObject {
  static let steps: [IntroStep] = [
    IntroStep(
      number: "01",
      title: "Choose what to set aside",
      detail: "Apps, categories and websites, held by Screen Time."),
    IntroStep(
      number: "02",
      title: "Pair a tag or a code",
      detail: "The session opens and closes by touch, not by will."),
    IntroStep(
      number: "03",
      title: "Meet the hour with a prayer",
      detail: "Every blocked app answers with the Collect or the Prayer of St. Benedict."),
  ]

  private let onRequestAuthorization: () -> Void

  init(onRequestAuthorization: @escaping () -> Void) {
    self.onRequestAuthorization = onRequestAuthorization
  }

  func begin() {
    onRequestAuthorization()
  }

  func alreadyHaveTag() {
    // A tag does not exempt anyone from the Screen Time permission.
    onRequestAuthorization()
  }
}

/// Screen 01 — dark accent-900 onboarding: cross mark, display title,
/// three numbered steps, Begin.
struct SapientiaIntroView: View {
  @StateObject private var model: IntroViewModel

  init(onRequestAuthorization: @escaping () -> Void) {
    _model = StateObject(
      wrappedValue: IntroViewModel(onRequestAuthorization: onRequestAuthorization))
  }

  var body: some View {
    VStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 0) {
        crossMark
        Text("Sapientia")
          .font(.sapientiaHeading(56))
          .kerning(1.1)
          .textCase(.uppercase)
          .foregroundColor(SapientiaTheme.background)
          .padding(.top, SapientiaTheme.space8)
        Text("Wisdom to perceive thee, diligence to seek thee, patience to wait for thee.")
          .font(.sapientiaBody(17))
          .lineSpacing(4)
          .foregroundColor(SapientiaTheme.onDark(0.72))
          .frame(maxWidth: 280, alignment: .leading)
          .padding(.top, SapientiaTheme.space4)
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
      .padding(.horizontal, SapientiaTheme.space8)

      VStack(alignment: .leading, spacing: 0) {
        Rectangle()
          .fill(SapientiaTheme.onDark(0.16))
          .frame(height: 1)

        ForEach(Array(IntroViewModel.steps.enumerated()), id: \.element.number) {
          index, step in
          HStack(alignment: .top, spacing: SapientiaTheme.space4) {
            Text(step.number)
              .font(.sapientiaHeading(15))
              .foregroundColor(SapientiaTheme.onDark(0.5))
              .frame(width: 20, alignment: .leading)
            VStack(alignment: .leading, spacing: 2) {
              Text(step.title)
                .font(.sapientiaHeading(20))
                .foregroundColor(SapientiaTheme.background)
              Text(step.detail)
                .font(.sapientiaBody(14))
                .lineSpacing(3)
                .foregroundColor(SapientiaTheme.onDark(0.6))
            }
          }
          .padding(.vertical, SapientiaTheme.space4)
          if index < IntroViewModel.steps.count - 1 {
            Rectangle()
              .fill(SapientiaTheme.onDark(0.12))
              .frame(height: 1)
          }
        }

        Button("Begin") {
          model.begin()
        }
        .buttonStyle(BlueprintPrimaryButtonStyle())
        .padding(.top, SapientiaTheme.space3)

        Button {
          model.alreadyHaveTag()
        } label: {
          Text("I already have a tag")
            .font(.sapientiaBody(14))
            .foregroundColor(SapientiaTheme.onDark(0.6))
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .padding(.top, SapientiaTheme.space4)
        .padding(.bottom, SapientiaTheme.space6)
      }
      .padding(.horizontal, SapientiaTheme.space8)
    }
    .background(SapientiaTheme.accent900.ignoresSafeArea())
  }

  private var crossMark: some View {
    SapientiaMark.steel(showLetters: false)
      .frame(width: 48, height: 48)
  }
}

#Preview {
  SapientiaIntroView {
    print("Request authorization")
  }
}
