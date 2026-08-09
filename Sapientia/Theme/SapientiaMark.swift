import SwiftUI

/// The Sapientia mark — the Medal of St. Benedict drawn as a wireframe:
/// two concentric rings, a flared cross on the axes, and the letters
/// C·S·P·B (*Crux Sancti Patris Benedicti*) in the quadrants. Vector, so
/// it stays crisp at any size and tints with the supplied colors.
///
/// Geometry matches the Claude Design "Sapientia — identity" mark on a
/// 200×200 artboard.
struct SapientiaMark: View {
  var ringColor: Color = SapientiaTheme.text
  var crossColor: Color = SapientiaTheme.accent
  var letterColor: Color = SapientiaTheme.text
  /// Quadrant letters are dropped below ~60pt per the design's reduction.
  var showLetters: Bool = true
  var lineWidth: CGFloat = 5

  var body: some View {
    GeometryReader { geo in
      let s = min(geo.size.width, geo.size.height) / 200

      ZStack {
        // Two hairline rings
        Circle()
          .strokeBorder(ringColor, lineWidth: lineWidth * s)
          .frame(width: 176 * s, height: 176 * s)
        Circle()
          .strokeBorder(ringColor, lineWidth: lineWidth * s)
          .frame(width: 160 * s, height: 160 * s)

        // Flared cross
        FlaredCross()
          .stroke(
            crossColor,
            style: StrokeStyle(lineWidth: lineWidth * s, lineJoin: .miter))
          .frame(width: 200 * s, height: 200 * s)

        if showLetters {
          letters(scale: s)
        }
      }
      .frame(width: geo.size.width, height: geo.size.height)
    }
    .aspectRatio(1, contentMode: .fit)
  }

  private func letters(scale s: CGFloat) -> some View {
    // Quadrant centres on the 200 artboard.
    let positions: [(String, CGFloat, CGFloat)] = [
      ("C", 66, 68), ("S", 134, 68), ("P", 66, 134), ("B", 134, 134),
    ]
    return ZStack {
      ForEach(positions, id: \.0) { glyph, x, y in
        Text(glyph)
          .font(.custom("BarlowCondensed-SemiBold", size: 26 * s))
          .foregroundColor(letterColor)
          .position(x: x * s, y: y * s)
      }
    }
    .frame(width: 200 * s, height: 200 * s)
  }
}

/// The cross pattée / flared cross of the St. Benedict medal.
private struct FlaredCross: Shape {
  func path(in rect: CGRect) -> Path {
    let s = min(rect.width, rect.height) / 200
    let pts: [(CGFloat, CGFloat)] = [
      (87, 46), (113, 46), (113, 54), (108, 58), (108, 92), (142, 92),
      (146, 87), (154, 87), (154, 113), (146, 113), (142, 108), (108, 108),
      (108, 142), (113, 146), (113, 154), (87, 154), (87, 146), (92, 142),
      (92, 108), (58, 108), (54, 113), (46, 113), (46, 87), (54, 87),
      (58, 92), (92, 92), (92, 58), (87, 54),
    ]
    var path = Path()
    for (i, p) in pts.enumerated() {
      let point = CGPoint(x: p.0 * s, y: p.1 * s)
      if i == 0 { path.move(to: point) } else { path.addLine(to: point) }
    }
    path.closeSubpath()
    return path
  }
}

// MARK: - Field variants (matching the design's app-icon fields)

extension SapientiaMark {
  /// Steel field: paper rings + accent-300 cross on accent-900 ground.
  static func steel(showLetters: Bool = true) -> some View {
    SapientiaMark(
      ringColor: SapientiaTheme.background,
      crossColor: SapientiaTheme.accent300,
      letterColor: SapientiaTheme.background,
      showLetters: showLetters
    )
  }

  /// Paper field: ink rings + accent cross on paper ground.
  static func paper(showLetters: Bool = true) -> some View {
    SapientiaMark(
      ringColor: SapientiaTheme.text,
      crossColor: SapientiaTheme.accent,
      letterColor: SapientiaTheme.text,
      showLetters: showLetters
    )
  }
}

#Preview {
  HStack(spacing: 24) {
    SapientiaMark.steel()
      .frame(width: 120, height: 120)
      .padding()
      .background(SapientiaTheme.accent900)
    SapientiaMark.paper()
      .frame(width: 120, height: 120)
      .padding()
      .background(SapientiaTheme.background)
  }
}
