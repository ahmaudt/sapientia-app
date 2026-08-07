import SwiftUI
import UIKit
import XCTest

@testable import sapientia

final class SapientiaThemeTests: XCTestCase {

  private func assertRGB(
    _ color: Color,
    _ hex: UInt32,
    _ label: String,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let uiColor = UIColor(color)
    var r: CGFloat = 0
    var g: CGFloat = 0
    var b: CGFloat = 0
    var a: CGFloat = 0
    XCTAssertTrue(
      uiColor.getRed(&r, green: &g, blue: &b, alpha: &a),
      "\(label) not RGB-convertible", file: file, line: line)

    let expectedR = CGFloat((hex >> 16) & 0xFF) / 255
    let expectedG = CGFloat((hex >> 8) & 0xFF) / 255
    let expectedB = CGFloat(hex & 0xFF) / 255
    let tolerance: CGFloat = 1.5 / 255

    XCTAssertEqual(r, expectedR, accuracy: tolerance, "\(label) red", file: file, line: line)
    XCTAssertEqual(g, expectedG, accuracy: tolerance, "\(label) green", file: file, line: line)
    XCTAssertEqual(b, expectedB, accuracy: tolerance, "\(label) blue", file: file, line: line)
  }

  func testCoreColorTokens() {
    assertRGB(SapientiaTheme.background, 0xF2F2F3, "background")
    assertRGB(SapientiaTheme.surface, 0xE9E9EA, "surface")
    assertRGB(SapientiaTheme.text, 0x1D1F20, "text")
    assertRGB(SapientiaTheme.accent, 0x5980A6, "accent")
  }

  func testAccentRampEndpoints() {
    assertRGB(SapientiaTheme.accent100, 0xEEF6FF, "accent100")
    assertRGB(SapientiaTheme.accent300, 0xB5D9FD, "accent300")
    assertRGB(SapientiaTheme.accent700, 0x416180, "accent700")
    assertRGB(SapientiaTheme.accent900, 0x1D2D3D, "accent900")
  }

  func testSpacingScale() {
    XCTAssertEqual(SapientiaTheme.space1, 3.4)
    XCTAssertEqual(SapientiaTheme.space2, 6.8)
    XCTAssertEqual(SapientiaTheme.space3, 10.2)
    XCTAssertEqual(SapientiaTheme.space4, 13.6)
    XCTAssertEqual(SapientiaTheme.space6, 20.4)
    XCTAssertEqual(SapientiaTheme.space8, 27.2)
  }

  func testCustomFontsAreRegistered() {
    XCTAssertNotNil(UIFont(name: "Barlow-Regular", size: 15), "Barlow-Regular missing")
    XCTAssertNotNil(UIFont(name: "Barlow-Medium", size: 15), "Barlow-Medium missing")
    XCTAssertNotNil(UIFont(name: "Barlow-Bold", size: 15), "Barlow-Bold missing")
    XCTAssertNotNil(
      UIFont(name: "BarlowCondensed-Regular", size: 20), "BarlowCondensed-Regular missing")
    XCTAssertNotNil(
      UIFont(name: "BarlowCondensed-SemiBold", size: 20), "BarlowCondensed-SemiBold missing")
  }

  func testThemeManagerReturnsFixedAccent() {
    assertRGB(ThemeManager.shared.themeColor, 0x5980A6, "themeColor")
  }
}
