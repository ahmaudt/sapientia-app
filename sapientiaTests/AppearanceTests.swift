import SwiftUI
import UIKit
import XCTest

@testable import sapientia

/// Covers the light/dark refresh: the `AppearanceSetting` mapping and the
/// appearance-aware theme tokens (the paper/ink swap), plus the fixed tokens
/// that keep the rite steel in either mode.
final class AppearanceTests: XCTestCase {

  private func rgba(
    _ color: Color, _ style: UIUserInterfaceStyle
  ) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
    let resolved = UIColor(color).resolvedColor(
      with: UITraitCollection(userInterfaceStyle: style))
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    resolved.getRed(&r, green: &g, blue: &b, alpha: &a)
    return (r, g, b, a)
  }

  private func assertHex(
    _ color: Color,
    _ style: UIUserInterfaceStyle,
    _ hex: UInt32,
    _ label: String,
    alpha: CGFloat = 1,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let c = rgba(color, style)
    let er = CGFloat((hex >> 16) & 0xFF) / 255
    let eg = CGFloat((hex >> 8) & 0xFF) / 255
    let eb = CGFloat(hex & 0xFF) / 255
    let tol: CGFloat = 1.5 / 255
    XCTAssertEqual(c.r, er, accuracy: tol, "\(label) red", file: file, line: line)
    XCTAssertEqual(c.g, eg, accuracy: tol, "\(label) green", file: file, line: line)
    XCTAssertEqual(c.b, eb, accuracy: tol, "\(label) blue", file: file, line: line)
    XCTAssertEqual(c.a, alpha, accuracy: 0.02, "\(label) alpha", file: file, line: line)
  }

  // MARK: - AppearanceSetting

  func testColorSchemeMapping() {
    XCTAssertEqual(AppearanceSetting.light.colorScheme, .light)
    XCTAssertEqual(AppearanceSetting.dark.colorScheme, .dark)
    XCTAssertNil(AppearanceSetting.system.colorScheme, "System defers to the device")
  }

  func testCasesOrderAndLabels() {
    XCTAssertEqual(AppearanceSetting.allCases, [.light, .dark, .system])
    XCTAssertEqual(AppearanceSetting.light.label, "Light")
    XCTAssertEqual(AppearanceSetting.dark.label, "Dark")
    XCTAssertEqual(AppearanceSetting.system.label, "System")
  }

  func testRawValueRoundTrip() {
    for setting in AppearanceSetting.allCases {
      XCTAssertEqual(AppearanceSetting(rawValue: setting.rawValue), setting)
    }
    XCTAssertNil(AppearanceSetting(rawValue: "nonsense"))
  }

  // MARK: - Appearance-aware tokens (the two grounds swap)

  func testBackgroundSwapsGrounds() {
    assertHex(SapientiaTheme.background, .light, 0xF2F2F3, "background light")
    assertHex(SapientiaTheme.background, .dark, 0x1D1F20, "background dark")
  }

  func testTextSwapsGrounds() {
    assertHex(SapientiaTheme.text, .light, 0x1D1F20, "text light")
    assertHex(SapientiaTheme.text, .dark, 0xF2F2F3, "text dark")
  }

  func testDividerReversesWithGround() {
    assertHex(SapientiaTheme.divider, .light, 0x1D1F20, "divider light", alpha: 0.16)
    assertHex(SapientiaTheme.divider, .dark, 0xF2F2F3, "divider dark", alpha: 0.18)
  }

  func testAccentTypeDeepOnPaperLightOnInk() {
    assertHex(SapientiaTheme.accent700, .light, 0x416180, "accent700 light")
    assertHex(SapientiaTheme.accent700, .dark, 0xB5D9FD, "accent700 dark")
  }

  func testAccentPressedStepsPastBasePerMode() {
    assertHex(SapientiaTheme.accentPressed, .light, 0x597EA3, "accentPressed light")
    assertHex(SapientiaTheme.accentPressed, .dark, 0x94BCE3, "accentPressed dark")
  }

  // MARK: - Fixed tokens (the rite reads the same in both modes)

  func testAccentFillHoldsInBothModes() {
    assertHex(SapientiaTheme.accent, .light, 0x5980A6, "accent light")
    assertHex(SapientiaTheme.accent, .dark, 0x5980A6, "accent dark")
  }

  func testSteelFieldHoldsInBothModes() {
    assertHex(SapientiaTheme.accent900, .light, 0x1D2D3D, "steel light")
    assertHex(SapientiaTheme.accent900, .dark, 0x1D2D3D, "steel dark")
  }

  func testOnDarkIsPaperInBothModes() {
    assertHex(SapientiaTheme.onDark(), .light, 0xF2F2F3, "onDark light")
    assertHex(SapientiaTheme.onDark(), .dark, 0xF2F2F3, "onDark dark")
  }

  func testPaperAndInkAreFixed() {
    assertHex(SapientiaTheme.paper, .light, 0xF2F2F3, "paper light")
    assertHex(SapientiaTheme.paper, .dark, 0xF2F2F3, "paper dark")
    assertHex(SapientiaTheme.ink, .light, 0x1D1F20, "ink light")
    assertHex(SapientiaTheme.ink, .dark, 0x1D1F20, "ink dark")
  }
}
