import SwiftUI

// The widget target does not compile the app's theme layer; these mirror
// SapientiaTheme's fixed palette (keep in sync with styles.css).
extension Color {
  static let sapientiaAccent = Color(red: 0x59 / 255, green: 0x80 / 255, blue: 0xA6 / 255)
  static let sapientiaAccent900 = Color(red: 0x1D / 255, green: 0x2D / 255, blue: 0x3D / 255)
}
