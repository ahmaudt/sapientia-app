import SwiftUI
import UIKit

/// A hold-to-confirm button: an accent fill sweeps left→right as it is held,
/// the label flipping to accent-900 over the fill; on completion it fires.
/// Used for taking a break, emergency unblock, and erase — deliberate,
/// hard-to-fat-finger actions. Squared, hairline-bordered.
struct BlueprintHoldButton: View {
  let title: String
  var holdDuration: Double = 1.3
  /// On a dark (accent-900) ground the empty state inverts to paper strokes.
  var onDark: Bool = false
  let action: () -> Void

  @State private var progress: CGFloat = 0

  private var borderColor: Color { onDark ? SapientiaTheme.paper : SapientiaTheme.accent }
  private var baseInk: Color { onDark ? SapientiaTheme.paper : SapientiaTheme.accent }
  private var filledInk: Color { onDark ? SapientiaTheme.accent900 : SapientiaTheme.paper }

  var body: some View {
    GeometryReader { geo in
      let w = geo.size.width
      ZStack(alignment: .leading) {
        Rectangle()
          .fill(SapientiaTheme.accent)
          .frame(width: w * progress)

        label(color: baseInk).frame(width: w)

        label(color: filledInk)
          .frame(width: w)
          .mask(
            HStack(spacing: 0) {
              Rectangle().frame(width: w * progress)
              Spacer(minLength: 0)
            }
          )
      }
      .frame(width: w, height: geo.size.height)
      .border(borderColor, width: 1)
    }
    .frame(height: 56)
    .contentShape(Rectangle())
    .onLongPressGesture(
      minimumDuration: holdDuration,
      maximumDistance: 60,
      pressing: { pressing in
        withAnimation(.linear(duration: pressing ? holdDuration : 0.2)) {
          progress = pressing ? 1 : 0
        }
      },
      perform: {
        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        action()
        withAnimation(.easeOut(duration: 0.2)) { progress = 0 }
      }
    )
    .accessibilityLabel(title)
    .accessibilityHint("Press and hold to confirm")
  }

  private func label(color: Color) -> some View {
    Text(title)
      .font(.sapientiaHeading(18))
      .kerning(1.0)
      .textCase(.uppercase)
      .foregroundColor(color)
      .frame(maxWidth: .infinity)
  }
}

#Preview {
  VStack(spacing: 20) {
    BlueprintHoldButton(title: "Hold to take a break", action: {})
    BlueprintHoldButton(title: "Hold to erase", onDark: true, action: {})
      .padding()
      .background(SapientiaTheme.accent900)
  }
  .padding()
  .background(SapientiaTheme.background)
}
