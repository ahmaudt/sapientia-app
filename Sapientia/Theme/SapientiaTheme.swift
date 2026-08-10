import SwiftUI
import UIKit

/// Design tokens for the Sapientia "Industry" design system.
/// Source of truth: docs/design/_ds/industry-*/styles.css — keep values in sync.
///
/// Light and dark are the same two grounds swapped: the paper becomes the
/// ink. Only the semantic tokens (`background`, `text`, `divider`, `surface`,
/// the accent *type*) are appearance-aware; the accent fill and the steel
/// `accent900` field are fixed, so the rite reads the same in either mode.
enum SapientiaTheme {
  // MARK: - Fixed grounds (the two the system owns)
  /// The light ground; also the reversed type on any accent or steel field.
  static let paper = Color(hex: "#f2f2f3")
  /// The dark ground; also the type on a light field.
  static let ink = Color(hex: "#1d1f20")

  /// Build an appearance-aware colour from a light/dark pair.
  private static func dynamic(light: Color, dark: Color) -> Color {
    Color(
      UIColor { traits in
        traits.userInterfaceStyle == .dark ? UIColor(dark) : UIColor(light)
      })
  }

  // MARK: - Core colors (appearance-aware)
  static let background = dynamic(light: paper, dark: ink)
  static let surface = dynamic(light: Color(hex: "#e9e9ea"), dark: Color(hex: "#2b2b2d"))
  static let text = dynamic(light: ink, dark: paper)
  static let accent = Color(hex: "#5980a6")
  static let divider = dynamic(light: ink.opacity(0.16), dark: paper.opacity(0.18))

  // MARK: - Accent ramp (OKLCH-derived, shared lightness scale)
  static let accent100 = Color(hex: "#eef6ff")
  static let accent200 = Color(hex: "#d6ebff")
  static let accent300 = Color(hex: "#b5d9fd")
  static let accent400 = Color(hex: "#94bce3")
  static let accent500 = Color(hex: "#749dc4")
  static let accent600 = Color(hex: "#597ea3")
  /// Accent *type* (links, labels): deep step on paper, light step on ink.
  static let accent700 = dynamic(light: Color(hex: "#416180"), dark: Color(hex: "#b5d9fd"))
  static let accent800 = Color(hex: "#2c455d")
  static let accent900 = Color(hex: "#1d2d3d")

  /// Pressed state for the accent fill: one step past the base per mode
  /// (accent-600 on paper, accent-400 on ink).
  static let accentPressed = dynamic(light: Color(hex: "#597ea3"), dark: Color(hex: "#94bce3"))

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
  /// Foreground on the steel `accent900` field. Fixed to paper: the rite is
  /// light-on-steel in both light and dark mode.
  static func onDark(_ opacity: Double = 1.0) -> Color {
    paper.opacity(opacity)
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
