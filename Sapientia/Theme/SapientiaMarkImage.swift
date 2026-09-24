import SwiftUI
import UIKit

/// `SapientiaMark` rasterised, for the places that cannot host a SwiftUI view.
///
/// Chiefly the Screen Time shield: `ShieldConfiguration` exposes an `icon` of
/// type `UIImage?` and no way to supply a view. Leaving it `nil` does *not*
/// mean "no icon" — ManagedSettingsUI substitutes its own system-blue
/// hourglass, which reads as off-palette against the accent-900 ground and
/// appears nowhere in the design.
enum SapientiaMarkImage {

  /// The mark as the shield draws it: wireframe rings and cross, no letters.
  ///
  /// `showLetters: false` follows the design's own reduction below ~60pt and
  /// has a second benefit here — the quadrant letters are the mark's only
  /// dependency on Barlow, which the app registers via its `Info.plist` and
  /// which is absent from the extension bundle. Without them the render is
  /// pure `Shape` geometry and cannot silently fall back to a system face.
  /// Drawn monochrome in accent-300, matching the kicker directly beneath it
  /// so mark and title read as a set. A two-tone treatment was tried and
  /// rejected: paper-tinted rings go muddy against the blue-cast ground, and
  /// tinting the cross `accent` sinks it into accent-900, which buries the
  /// one part of the mark that carries meaning.
  ///
  /// Note these are fixed tints, not the appearance-aware `SapientiaTheme.text`.
  /// The shield's ground is steel in both modes, and the extension is not
  /// guaranteed to inherit dark traits — `text` could resolve to near-black ink
  /// and vanish.
  static func shieldIcon(
    size: CGFloat = 96,
    scale: CGFloat = 3
  ) -> UIImage? {
    markImage(size: size, scale: scale, showLetters: false)
  }

  /// Renders the mark at a point size, honouring the caller's colours.
  ///
  /// Returns `nil` off the main thread rather than hopping to it: the only
  /// caller is a shield data source, and a `nil` icon degrades to Apple's
  /// hourglass. That is a far better failure than blocking or trapping inside
  /// an extension the system is waiting on.
  static func markImage(
    size: CGFloat,
    scale: CGFloat,
    showLetters: Bool,
    ringColor: Color = SapientiaTheme.accent300,
    crossColor: Color = SapientiaTheme.accent300
  ) -> UIImage? {
    guard Thread.isMainThread else { return nil }

    return MainActor.assumeIsolated {
      let mark = SapientiaMark(
        ringColor: ringColor,
        crossColor: crossColor,
        letterColor: ringColor,
        showLetters: showLetters,
        lineWidth: 5
      )
      .frame(width: size, height: size)

      let renderer = ImageRenderer(content: mark)
      renderer.scale = scale
      return renderer.uiImage
    }
  }
}
