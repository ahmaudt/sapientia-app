import SwiftUI

/// The "Websites" row in the rule editor (flow 07): a blueprint row showing
/// the blocked-domain count with an Edit action opening the Websites stage.
struct BlockedProfileDomainSelector: View {
  var domains: [String]
  var buttonAction: () -> Void
  var allowMode: Bool = false
  var disabled: Bool = false
  var disabledText: String?

  private var domainCount: Int { domains.count }

  private var caption: String {
    if domainCount == 0 { return "None" }
    return "\(domainCount) \(domainCount == 1 ? "domain" : "domains") \(allowMode ? "allowed" : "blocked")"
  }

  var body: some View {
    BlueprintListRow(
      title: "Websites",
      caption: caption,
      onTap: disabled ? nil : buttonAction
    ) {
      if !disabled {
        BlueprintRowAction(label: domainCount == 0 ? "Add" : "Edit", action: buttonAction)
      }
    }

    if let disabledText, disabled {
      Text(disabledText)
        .font(.sapientiaBody(13))
        .foregroundColor(SapientiaTheme.accent700)
        .padding(.top, 4)
    }
  }
}

#Preview {
  VStack(spacing: 0) {
    BlockedProfileDomainSelector(domains: ["reddit.com", "x.com"], buttonAction: {})
    BlockedProfileDomainSelector(domains: [], buttonAction: {}, allowMode: true)
  }
  .padding()
  .background(SapientiaTheme.background)
}
