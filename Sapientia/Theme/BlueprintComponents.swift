import SwiftUI

// Blueprint-style components: squared corners, hairline borders,
// registration marks. Mirrors .blueprint/.corner/.btn/.seg in the
// design system's styles.css.

// MARK: - Registration corner marks

/// A small cross ("registration mark") drawn at each corner of a blueprint
/// element, offset outward by 6pt, matching `.blueprint > .corner`.
struct BlueprintCornerMarks: View {
  var color: Color = SapientiaTheme.text.opacity(0.55)

  var body: some View {
    GeometryReader { geo in
      let positions: [CGPoint] = [
        CGPoint(x: 0, y: 0),
        CGPoint(x: geo.size.width, y: 0),
        CGPoint(x: 0, y: geo.size.height),
        CGPoint(x: geo.size.width, y: geo.size.height),
      ]
      ForEach(0..<4, id: \.self) { index in
        CrossMark()
          .stroke(color, lineWidth: 1)
          .frame(width: 11, height: 11)
          .position(positions[index])
      }
    }
    .allowsHitTesting(false)
  }
}

private struct CrossMark: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.midX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
    path.move(to: CGPoint(x: rect.minX, y: rect.midY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
    return path
  }
}

// MARK: - Blueprint card

/// Hairline-bordered, squared card with registration marks at its corners.
struct BlueprintCard<Content: View>: View {
  var padding: CGFloat = SapientiaTheme.space4
  var markColor: Color = SapientiaTheme.text.opacity(0.55)
  var borderColor: Color = SapientiaTheme.divider
  @ViewBuilder var content: () -> Content

  var body: some View {
    content()
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(padding)
      .border(borderColor, width: 1)
      .overlay(BlueprintCornerMarks(color: markColor))
  }
}

// MARK: - Buttons

/// Solid accent, uppercase condensed type, squared, with corner marks.
struct BlueprintPrimaryButtonStyle: ButtonStyle {
  var fontSize: CGFloat = 20

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.sapientiaHeading(fontSize))
      .kerning(fontSize * 0.06)
      .textCase(.uppercase)
      .foregroundColor(SapientiaTheme.background)
      .frame(maxWidth: .infinity)
      .padding(SapientiaTheme.space4)
      .background(
        configuration.isPressed ? SapientiaTheme.accent700 : SapientiaTheme.accent
      )
      .border(SapientiaTheme.accent, width: 1)
      .overlay(BlueprintCornerMarks())
  }
}

/// Hairline-bordered transparent button.
struct BlueprintSecondaryButtonStyle: ButtonStyle {
  var fontSize: CGFloat = 14
  var foreground: Color = SapientiaTheme.text
  var borderColor: Color = SapientiaTheme.divider

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.sapientiaHeading(fontSize))
      .kerning(fontSize * 0.06)
      .foregroundColor(foreground)
      .padding(.vertical, SapientiaTheme.space2)
      .padding(.horizontal, SapientiaTheme.space3 * 1.2)
      .background(
        configuration.isPressed ? SapientiaTheme.text.opacity(0.07) : Color.clear
      )
      .border(borderColor, width: 1)
  }
}

// MARK: - Segmented picker

/// Squared segmented control matching `.seg`/`.seg-opt`: selected segment
/// fills with accent, options divided by hairlines.
struct SapientiaSegmentedPicker<Option: Hashable>: View {
  let options: [Option]
  let label: (Option) -> String
  @Binding var selection: Option
  var isDisabled: (Option) -> Bool = { _ in false }

  var body: some View {
    HStack(spacing: 0) {
      ForEach(Array(options.enumerated()), id: \.element) { index, option in
        let selected = option == selection
        let disabled = isDisabled(option)
        Button {
          if !disabled { selection = option }
        } label: {
          Text(label(option))
            .font(.sapientiaHeading(16))
            .textCase(.uppercase)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 7)
            .foregroundColor(
              selected
                ? SapientiaTheme.background
                : SapientiaTheme.text.opacity(disabled ? 0.35 : 1)
            )
            .background(selected ? SapientiaTheme.accent : Color.clear)
        }
        .buttonStyle(.plain)
        if index < options.count - 1 {
          Rectangle()
            .fill(SapientiaTheme.divider)
            .frame(width: 1)
        }
      }
    }
    .fixedSize(horizontal: false, vertical: true)
    .border(SapientiaTheme.divider, width: 1)
  }
}

// MARK: - Toggle

/// Squared 44×26 toggle matching the mockup's switch rows.
struct BlueprintToggleStyle: ToggleStyle {
  func makeBody(configuration: Configuration) -> some View {
    HStack {
      configuration.label
      Spacer()
      ZStack(alignment: configuration.isOn ? .trailing : .leading) {
        Rectangle()
          .fill(configuration.isOn ? SapientiaTheme.accent : SapientiaTheme.surface)
          .border(
            configuration.isOn ? SapientiaTheme.accent : SapientiaTheme.divider,
            width: 1)
        Rectangle()
          .fill(SapientiaTheme.background)
          .border(
            configuration.isOn ? Color.clear : SapientiaTheme.divider, width: 1
          )
          .frame(width: 18, height: 18)
          .padding(3)
      }
      .frame(width: 44, height: 26)
      .onTapGesture {
        withAnimation(.easeInOut(duration: 0.15)) {
          configuration.isOn.toggle()
        }
      }
    }
  }
}

// MARK: - Section header

/// Uppercase section label with a hairline rule beneath, matching the
/// mockup's h6 + border-bottom section headers.
struct SectionHeaderLabel: View {
  let title: String

  var body: some View {
    VStack(alignment: .leading, spacing: SapientiaTheme.space3) {
      Text(title)
        .sapientiaKicker()
      Rectangle()
        .fill(SapientiaTheme.divider)
        .frame(height: 1)
    }
  }
}

// MARK: - Radio row

/// Circular radio matching `.radio .dot` (the one intentionally round
/// element in the system).
struct SapientiaRadioRow: View {
  let title: String
  let subtitle: String?
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      HStack(spacing: SapientiaTheme.space3) {
        ZStack {
          Circle()
            .strokeBorder(
              isSelected ? SapientiaTheme.accent : SapientiaTheme.divider,
              lineWidth: 1.5)
          if isSelected {
            Circle()
              .fill(SapientiaTheme.accent)
              .padding(4)
          }
        }
        .frame(width: 20, height: 20)
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.sapientiaBody(17))
            .foregroundColor(SapientiaTheme.text)
          if let subtitle {
            Text(subtitle)
              .font(.sapientiaBody(13))
              .foregroundColor(SapientiaTheme.text.opacity(0.55))
          }
        }
        Spacer()
      }
      .padding(.vertical, SapientiaTheme.space4)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
