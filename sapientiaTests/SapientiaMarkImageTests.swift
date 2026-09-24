import CoreGraphics
import UIKit
import XCTest

@testable import sapientia

/// The shield takes a `UIImage` and nothing else, so the mark has to survive
/// a trip through `ImageRenderer` before it can appear there. These cover the
/// two ways that trip can fail quietly: wrong size, or a blank bitmap.
@MainActor
final class SapientiaMarkImageTests: XCTestCase {

  func testShieldIconRendersAtRequestedPointSize() {
    guard let icon = SapientiaMarkImage.shieldIcon(size: 96, scale: 3) else {
      return XCTFail("shield icon failed to render")
    }
    XCTAssertEqual(icon.size.width, 96, accuracy: 1)
    XCTAssertEqual(icon.size.height, 96, accuracy: 1)
    XCTAssertEqual(icon.scale, 3, accuracy: 0.01)
  }

  /// A blank-but-present image is worse than none: `nil` at least falls back
  /// to Apple's hourglass, whereas an empty bitmap leaves a hole where the
  /// mark should be. Assert real ink landed on the canvas.
  func testShieldIconDrawsVisibleInk() {
    guard let icon = SapientiaMarkImage.shieldIcon(size: 96, scale: 3) else {
      return XCTFail("shield icon failed to render")
    }
    let coverage = opaqueCoverage(of: icon)
    XCTAssertGreaterThan(coverage, 0.01, "mark rendered blank")
    XCTAssertLessThan(coverage, 0.9, "mark rendered as a filled block, not a wireframe")
  }

  /// The rings and cross are pure `Shape` geometry; the quadrant letters are
  /// the only part needing Barlow, which is registered by the app's
  /// Info.plist and absent from the extension bundle. Dropping them is what
  /// makes the render font-independent, so pin that the icon path does.
  func testShieldIconOmitsQuadrantLetters() {
    let withoutLetters = SapientiaMarkImage.shieldIcon(size: 96, scale: 3)
    let withLetters = SapientiaMarkImage.markImage(
      size: 96, scale: 3, showLetters: true)

    guard let withoutLetters, let withLetters else {
      return XCTFail("mark failed to render")
    }
    XCTAssertLessThan(
      opaqueCoverage(of: withoutLetters),
      opaqueCoverage(of: withLetters),
      "letters should add ink; the shield icon is expected to omit them")
  }

  // MARK: - Helpers

  /// Fraction of pixels carrying any alpha at all.
  private func opaqueCoverage(of image: UIImage) -> Double {
    guard let cgImage = image.cgImage else { return 0 }
    let width = cgImage.width
    let height = cgImage.height
    guard width > 0, height > 0 else { return 0 }

    var pixels = [UInt8](repeating: 0, count: width * height * 4)
    guard
      let context = CGContext(
        data: &pixels,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { return 0 }

    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
    let opaque = stride(from: 3, to: pixels.count, by: 4)
      .reduce(0) { $0 + (pixels[$1] > 0 ? 1 : 0) }
    return Double(opaque) / Double(width * height)
  }
}
