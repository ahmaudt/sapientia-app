import SwiftUI

// Blueprint list rows and stat grid — the "rules replace containers"
// primitives from the conversion spec. A list is an uppercase header with a
// rule under it and a rule under each row; a stat grid is hairline-divided
// cells. Nothing rounded, nothing filled.

// MARK: - List row

/// The single row used across the Setup/Records/System screens: a title,
/// optional caption, an optional trailing value/control, and a bottom
/// hairline. Replaces every grouped-list `Form` row.
struct BlueprintListRow<Trailing: View>: View {
  let title: String
  var caption: String? = nil
  var titleFont: Font = .sapientiaBody(17)
  var onTap: (() -> Void)? = nil
  @ViewBuilder var trailing: () -> Trailing

  var body: some View {
    Button {
      onTap?()
    } label: {
      HStack(alignment: .center, spacing: SapientiaTheme.space3) {
        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(titleFont)
            .foregroundColor(SapientiaTheme.text)
          if let caption {
            Text(caption)
              .font(.sapientiaBody(13))
              .foregroundColor(SapientiaTheme.text.opacity(0.55))
          }
        }
        Spacer(minLength: SapientiaTheme.space3)
        trailing()
      }
      .padding(.vertical, SapientiaTheme.space4)
      .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
    .disabled(onTap == nil)
    .overlay(alignment: .bottom) {
      Rectangle()
        .fill(SapientiaTheme.divider)
        .frame(height: 1)
    }
  }
}

extension BlueprintListRow where Trailing == SwiftUI.EmptyView {
  init(title: String, caption: String? = nil, onTap: (() -> Void)? = nil) {
    self.init(
      title: title, caption: caption, onTap: onTap, trailing: { SwiftUI.EmptyView() })
  }
}

/// Convenience trailing: a muted value string (right-aligned meta).
struct BlueprintRowValue: View {
  let value: String
  var color: Color = SapientiaTheme.text.opacity(0.55)
  var body: some View {
    Text(value)
      .font(.sapientiaBody(15))
      .foregroundColor(color)
  }
}

/// Convenience trailing: an accent "action" word (e.g. Edit / Remove).
struct BlueprintRowAction: View {
  let label: String
  let action: () -> Void
  var body: some View {
    Button(label, action: action)
      .font(.sapientiaHeading(13))
      .kerning(1.0)
      .textCase(.uppercase)
      .foregroundColor(SapientiaTheme.accent700)
      .buttonStyle(.plain)
  }
}

// MARK: - Form section

/// A blueprint section: an uppercase header with a rule under it, the
/// content stacked directly on the ground (rows separate themselves), and
/// an optional muted footer. Replaces `Form`/`Section` grouped cards.
struct BlueprintFormSection<Content: View>: View {
  let title: String?
  var footer: String? = nil
  @ViewBuilder var content: () -> Content

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      if let title {
        SectionHeaderLabel(title: title)
      }
      content()
      if let footer {
        Text(footer)
          .font(.sapientiaBody(13))
          .lineSpacing(3)
          .foregroundColor(SapientiaTheme.text.opacity(0.55))
          .padding(.top, SapientiaTheme.space3)
      }
    }
  }
}

// MARK: - Stat grid

struct BlueprintStatCell: Identifiable {
  let id = UUID()
  let value: String
  let label: String
  let action: (() -> Void)?
}

/// Two or three cells, 1px gutters over a divider ground, numeral in Barlow
/// Condensed over an uppercase label. Each cell has its OWN optional tap.
struct BlueprintStatGrid: View {
  let cells: [BlueprintStatCell]
  var numeralSize: CGFloat = 30

  var body: some View {
    HStack(spacing: 1) {
      ForEach(cells) { cell in
        Button {
          cell.action?()
        } label: {
          VStack(alignment: .leading, spacing: 2) {
            Text(cell.value)
              .font(.sapientiaHeading(numeralSize))
              .foregroundColor(SapientiaTheme.text)
            Text(cell.label)
              .font(.sapientiaHeading(12))
              .kerning(1.0)
              .textCase(.uppercase)
              .foregroundColor(SapientiaTheme.text.opacity(0.55))
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
          .padding(.vertical, SapientiaTheme.space3)
          .padding(.horizontal, SapientiaTheme.space4)
          .background(SapientiaTheme.background)
          .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(cell.action == nil)
      }
    }
    .background(SapientiaTheme.divider)
    .border(SapientiaTheme.divider, width: 1)
    .fixedSize(horizontal: false, vertical: true)
  }
}
