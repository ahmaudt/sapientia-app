import SwiftUI

/// Full-screen presentation shell replacing `.sheet` detents for the Setup /
/// Records / System sub-screens: a header (leading action, centered
/// uppercase title, optional trailing action), a scrollable body, and an
/// optional bottom action block. Light by default; `.dark` uses the
/// accent-900 ground reserved for rites.
struct BlueprintStage<Content: View, Bottom: View>: View {
  enum Field { case light, dark }

  let title: String
  var field: Field = .light
  var leadingLabel: String? = "Cancel"
  var leadingAction: (() -> Void)? = nil
  var trailingLabel: String? = nil
  var trailingAction: (() -> Void)? = nil
  /// When false the content is placed directly (no ScrollView) — for
  /// full-bleed system views like the Screen Time picker that scroll
  /// themselves.
  var scrolls: Bool = true
  @ViewBuilder var content: () -> Content
  @ViewBuilder var bottom: () -> Bottom

  private var ground: Color {
    field == .dark ? SapientiaTheme.accent900 : SapientiaTheme.background
  }
  private var ink: Color {
    field == .dark ? SapientiaTheme.paper : SapientiaTheme.text
  }
  private var actionColor: Color {
    field == .dark ? SapientiaTheme.paper.opacity(0.85) : SapientiaTheme.accent700
  }
  private var dividerColor: Color {
    field == .dark ? SapientiaTheme.paper.opacity(0.16) : SapientiaTheme.divider
  }

  var body: some View {
    VStack(spacing: 0) {
      header
      if scrolls {
        ScrollView(showsIndicators: false) {
          content()
            .padding(.horizontal, SapientiaTheme.space6)
            .padding(.top, SapientiaTheme.space6)
            .padding(.bottom, SapientiaTheme.space8)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      } else {
        content()
          .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
      }
      bottom()
        .padding(.horizontal, SapientiaTheme.space6)
        .padding(.bottom, SapientiaTheme.space6)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
    .background(ground.ignoresSafeArea())
  }

  private var header: some View {
    HStack {
      headerButton(leadingLabel, leadingAction)
      Spacer()
      Text(title)
        .font(.sapientiaHeading(13))
        .kerning(1.6)
        .textCase(.uppercase)
        .foregroundColor(ink.opacity(0.55))
      Spacer()
      // Balance the leading control; use the trailing action or a hidden twin.
      if trailingLabel != nil {
        headerButton(trailingLabel, trailingAction)
      } else if let leadingLabel {
        headerButton(leadingLabel, nil).opacity(0).disabled(true)
      }
    }
    .padding(.horizontal, SapientiaTheme.space6)
    .padding(.top, SapientiaTheme.space6)
    .padding(.bottom, SapientiaTheme.space4)
    .overlay(alignment: .bottom) {
      Rectangle().fill(dividerColor).frame(height: 1)
    }
  }

  @ViewBuilder
  private func headerButton(_ label: String?, _ action: (() -> Void)?) -> some View {
    if let label {
      Button(label) { action?() }
        .font(.sapientiaBody(15))
        .foregroundColor(actionColor)
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
  }
}

// Convenience: stage with no bottom action block.
extension BlueprintStage where Bottom == SwiftUI.EmptyView {
  init(
    title: String,
    field: Field = .light,
    leadingLabel: String? = "Cancel",
    leadingAction: (() -> Void)? = nil,
    trailingLabel: String? = nil,
    trailingAction: (() -> Void)? = nil,
    scrolls: Bool = true,
    @ViewBuilder content: @escaping () -> Content
  ) {
    self.init(
      title: title, field: field,
      leadingLabel: leadingLabel, leadingAction: leadingAction,
      trailingLabel: trailingLabel, trailingAction: trailingAction,
      scrolls: scrolls,
      content: content, bottom: { SwiftUI.EmptyView() })
  }
}

#Preview {
  BlueprintStage(
    title: "Websites",
    leadingLabel: "Cancel", leadingAction: {},
    trailingLabel: "Done", trailingAction: {}
  ) {
    VStack(alignment: .leading, spacing: 0) {
      SectionHeaderLabel(title: "Blocked — 2")
      BlueprintListRow(title: "reddit.com") {
        BlueprintRowAction(label: "Remove") {}
      }
      BlueprintListRow(title: "x.com") {
        BlueprintRowAction(label: "Remove") {}
      }
    }
  }
}
