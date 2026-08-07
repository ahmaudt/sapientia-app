import SwiftUI

/// Full-screen prayer moment (accent-900) shown before an unblock: the
/// Prayer of St. Benedict or the Collect of the day, per the block-screen
/// prayer setting. "Amen" proceeds; Cancel (optional) backs out.
struct PrayerInterstitialView: View {
  var onAmen: () -> Void
  var onCancel: (() -> Void)? = nil

  private var prayer: (title: String, text: String) {
    ShieldContent.prayerText(
      prayer: PrayerSettings.blockScreenPrayer,
      date: Date()
    )
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if let onCancel {
        HStack {
          Button("Cancel", action: onCancel)
            .font(.sapientiaBody(15))
            .foregroundColor(SapientiaTheme.onDark(0.7))
            .buttonStyle(.plain)
          Spacer()
        }
      }

      Spacer()

      Text(prayer.title)
        .font(.sapientiaHeading(13))
        .kerning(2.0)
        .textCase(.uppercase)
        .foregroundColor(SapientiaTheme.accent300)

      Text(prayer.text)
        .font(.sapientiaDisplay(25))
        .lineSpacing(8)
        .foregroundColor(SapientiaTheme.background)
        .padding(.top, SapientiaTheme.space4)

      Spacer()

      Rectangle()
        .fill(SapientiaTheme.onDark(0.16))
        .frame(height: 1)

      Button("Amen") {
        onAmen()
      }
      .buttonStyle(BlueprintPrimaryButtonStyle())
      .padding(.top, SapientiaTheme.space6)
    }
    .padding(.horizontal, SapientiaTheme.space8)
    .padding(.vertical, SapientiaTheme.space6)
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
    .background(SapientiaTheme.accent900.ignoresSafeArea())
  }
}

/// Wraps a strategy's stop view (QR scanner, pause picker) so the prayer
/// stands in front of it when the profile asks for it.
struct PrayerGatedView: View {
  let content: AnyView
  @Environment(\.dismiss) private var dismiss
  @State private var prayed = false

  var body: some View {
    if prayed {
      content
    } else {
      PrayerInterstitialView(
        onAmen: { prayed = true },
        onCancel: { dismiss() }
      )
    }
  }
}

#Preview {
  PrayerInterstitialView(onAmen: {}, onCancel: {})
}
