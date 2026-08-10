import SwiftUI

struct StrategyRow: View {
  @EnvironmentObject var themeManager: ThemeManager

  enum AccessoryStyle {
    case selection
    case chevron
    case none
  }

  let strategy: BlockingStrategy
  let isSelected: Bool
  let onTap: () -> Void
  var accessoryStyle: AccessoryStyle = .selection

  private func backgroundColor(for tag: BlockingStrategyTag) -> Color {
    if tag == .beta {
      return SapientiaTheme.accent100
    }

    return SapientiaTheme.accent100
  }

  private func foregroundColor(for tag: BlockingStrategyTag) -> Color {
    if tag == .beta {
      return SapientiaTheme.accent700
    }

    return SapientiaTheme.accent800
  }

  var body: some View {
    Button(action: onTap) {
      VStack(alignment: .leading, spacing: 8) {
        HStack(alignment: .center, spacing: 8) {
          BlockingStrategyIconImage(strategy: strategy)
            .font(.subheadline)
            .foregroundColor(SapientiaTheme.text.opacity(0.55))
            .frame(width: 34, height: 34)

          Text(strategy.name)
            .font(.headline)
            .foregroundStyle(
              accessoryStyle == .selection && isSelected ? SapientiaTheme.accent : SapientiaTheme.text)

          Spacer(minLength: 8)

          if accessoryStyle == .selection {
            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
              .foregroundColor(isSelected ? SapientiaTheme.accent : SapientiaTheme.text.opacity(0.55))
              .font(.system(size: 20))
          } else if accessoryStyle == .chevron {
            Image(systemName: "chevron.right")
              .foregroundColor(SapientiaTheme.text.opacity(0.55))
              .font(.system(size: 14, weight: .semibold))
          }
        }

        Text(strategy.description)
          .font(.subheadline)
          .foregroundColor(SapientiaTheme.text.opacity(0.55))
          .lineLimit(2)

        if !strategy.tags.isEmpty {
          HStack(spacing: 6) {
            ForEach(strategy.tags, id: \.self) { tag in
              Text(tag.title)
                .font(.caption2)
                .fontWeight(tag == .beta ? .semibold : .medium)
                .foregroundStyle(foregroundColor(for: tag))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(backgroundColor(for: tag))
                .border(SapientiaTheme.divider, width: 1)
            }
          }
        }
      }
      .padding(.vertical, 4)
    }
    .buttonStyle(PlainButtonStyle())
  }
}

#Preview {
  StrategyRow(strategy: NFCBlockingStrategy(), isSelected: true, onTap: {})
}
