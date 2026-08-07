import SwiftUI

/// Sapientia uses one fixed, intentional palette (the Industry design
/// system's slate blue). The class API survives because the ShieldConfig
/// extension reads `themeColor`; the old 19-color picker is gone. The
/// legacy stored color-name key is intentionally ignored (never read) so
/// upgrading users cannot crash on a stale value.
class ThemeManager: ObservableObject {
  static let shared = ThemeManager()

  static let fixedColorName = "Sapientia Blue"

  // Kept for API compatibility with call sites that enumerate colors.
  static let availableColors: [(name: String, color: Color)] = [
    (fixedColorName, Color(hex: "#5980a6"))
  ]

  var selectedColorName: String {
    get { Self.fixedColorName }
    set { _ = newValue }
  }

  var themeColor: Color {
    Self.availableColors.first!.color
  }

  func setTheme(named name: String) {
    // Fixed palette: no-op.
  }
}

extension Color {
  init(hex: String) {
    let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
    var int: UInt64 = 0
    Scanner(string: hex).scanHexInt64(&int)
    let a: UInt64
    let r: UInt64
    let g: UInt64
    let b: UInt64
    switch hex.count {
    case 3:  // RGB (12-bit)
      (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
    case 6:  // RGB (24-bit)
      (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
    case 8:  // ARGB (32-bit)
      (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
    default:
      (a, r, g, b) = (1, 1, 1, 0)
    }

    self.init(
      .sRGB,
      red: Double(r) / 255,
      green: Double(g) / 255,
      blue: Double(b) / 255,
      opacity: Double(a) / 255
    )
  }

  func toHex() -> String? {
    let uiColor = UIColor(self)
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0

    guard uiColor.getRed(&r, green: &g, blue: &b, alpha: &a) else {
      return nil
    }

    let rgb: Int = (Int)(r * 255) << 16 | (Int)(g * 255) << 8 | (Int)(b * 255) << 0

    return String(format: "#%06x", rgb)
  }
}
