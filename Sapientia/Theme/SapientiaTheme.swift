import SwiftUI

/// Design tokens for the Sapientia "Industry" design system.
/// Source of truth: docs/design/_ds/industry-*/styles.css — keep values in sync.
enum SapientiaTheme {
  // MARK: - Core colors
  static let background = Color(hex: "#f2f2f3")
  static let surface = Color(hex: "#e9e9ea")
  static let text = Color(hex: "#1d1f20")
  static let accent = Color(hex: "#5980a6")
  static let divider = Color(hex: "#1d1f20").opacity(0.16)

  // MARK: - Accent ramp (OKLCH-derived, shared lightness scale)
  static let accent100 = Color(hex: "#eef6ff")
  static let accent200 = Color(hex: "#d6ebff")
  static let accent300 = Color(hex: "#b5d9fd")
  static let accent400 = Color(hex: "#94bce3")
  static let accent500 = Color(hex: "#749dc4")
  static let accent600 = Color(hex: "#597ea3")
  static let accent700 = Color(hex: "#416180")
  static let accent800 = Color(hex: "#2c455d")
  static let accent900 = Color(hex: "#1d2d3d")

  // MARK: - Neutral ramp
  static let neutral100 = Color(hex: "#f5f5f8")
  static let neutral200 = Color(hex: "#e7e7ea")
  static let neutral300 = Color(hex: "#d4d4d7")
  static let neutral500 = Color(hex: "#98989b")
  static let neutral700 = Color(hex: "#5d5d60")
  static let neutral900 = Color(hex: "#2b2b2d")

  // MARK: - Spacing
  static let space1: CGFloat = 3.4
  static let space2: CGFloat = 6.8
  static let space3: CGFloat = 10.2
  static let space4: CGFloat = 13.6
  static let space6: CGFloat = 20.4
  static let space8: CGFloat = 27.2

  // MARK: - Text on dark (ritual screens)
  /// Foreground on accent-900 backgrounds, per mockup color-mix values.
  static func onDark(_ opacity: Double = 1.0) -> Color {
    background.opacity(opacity)
  }
}

// MARK: - Typography
extension Font {
  /// Barlow Condensed SemiBold — headings, numerals, buttons.
  static func sapientiaHeading(_ size: CGFloat) -> Font {
    .custom("BarlowCondensed-SemiBold", size: size)
  }

  /// Barlow Condensed Regular — large display prayer text.
  static func sapientiaDisplay(_ size: CGFloat) -> Font {
    .custom("BarlowCondensed-Regular", size: size)
  }

  /// Barlow Regular — body copy.
  static func sapientiaBody(_ size: CGFloat) -> Font {
    .custom("Barlow-Regular", size: size)
  }

  /// Barlow Medium — emphasized body copy.
  static func sapientiaBodyMedium(_ size: CGFloat) -> Font {
    .custom("Barlow-Medium", size: size)
  }
}

extension Text {
  /// Uppercase kicker/label style (h6 in the design system).
  func sapientiaKicker(color: Color = SapientiaTheme.text.opacity(0.55)) -> Text {
    self
      .font(.sapientiaHeading(13))
      .kerning(1.0)
      .foregroundColor(color)
  }
}
