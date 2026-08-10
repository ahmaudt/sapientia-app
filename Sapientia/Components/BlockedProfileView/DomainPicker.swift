import SwiftUI

/// Screen 09 — Websites. A BlueprintStage framing an add-field and a ruled
/// list of blocked domains. The domain add/remove logic is unchanged; only
/// the layout and (full-screen) presentation moved off the grouped Form.
///
/// STAGE RECIPE (reference for the other Setup pickers):
///   1. The picker's own body = `BlueprintStage(title:leading:trailing:) { … }`
///      — no NavigationStack/Form/toolbar of its own.
///   2. Both presenters (`BlockedProfileView`, `GuidedBlockedProfileCreationView`)
///      present it via `.fullScreenCover(isPresented:)`, not `.sheet`.
///   3. Dismiss with `isPresented = false` (works under fullScreenCover).
struct DomainPicker: View {
  @Binding var domains: [String]
  @Binding var isPresented: Bool

  var allowMode: Bool = false

  @State private var newDomain: String = ""
  @State private var showingError: Bool = false
  @State private var errorMessage: String = ""

  private var subtitle: String {
    "Websites are held by the on-device filter. Sub-domains are covered; the address itself never leaves the phone."
  }

  var body: some View {
    BlueprintStage(
      title: "Websites",
      leadingLabel: "Cancel",
      leadingAction: { isPresented = false },
      trailingLabel: "Done",
      trailingAction: { isPresented = false }
    ) {
      VStack(alignment: .leading, spacing: SapientiaTheme.space6) {
        addField
        list
        Text(subtitle)
          .font(.sapientiaBody(13))
          .lineSpacing(3)
          .foregroundColor(SapientiaTheme.text.opacity(0.62))
      }
    }
    .alert("Error", isPresented: $showingError) {
      Button("OK") {}
    } message: {
      Text(errorMessage)
    }
  }

  private var addField: some View {
    VStack(alignment: .leading, spacing: SapientiaTheme.space3) {
      SectionHeaderLabel(title: "Add a domain")
      HStack(spacing: SapientiaTheme.space3) {
        TextField("news.example.com", text: $newDomain)
          .font(.sapientiaBody(17))
          .autocapitalization(.none)
          .keyboardType(.URL)
          .textContentType(.URL)
          .onSubmit { addDomain() }
        Button("Add") { addDomain() }
          .buttonStyle(BlueprintSecondaryButtonStyle())
          .disabled(newDomain.isEmpty || domains.count >= DomainValidation.maxDomains)
      }
      .padding(.bottom, SapientiaTheme.space2)
    }
  }

  private var list: some View {
    VStack(alignment: .leading, spacing: 0) {
      SectionHeaderLabel(
        title: (allowMode ? "Allowed" : "Blocked") + " — \(domains.count)")
      if domains.isEmpty {
        Text("No websites yet")
          .font(.sapientiaBody(15))
          .foregroundColor(SapientiaTheme.text.opacity(0.55))
          .padding(.vertical, SapientiaTheme.space4)
      } else {
        ForEach(domains, id: \.self) { domain in
          BlueprintListRow(title: domain) {
            BlueprintRowAction(label: "Remove") { remove(domain) }
          }
        }
      }
    }
  }

  private func addDomain() {
    let trimmed = DomainValidation.normalize(newDomain)
    guard !trimmed.isEmpty else { return showError("Please enter a domain") }
    guard domains.count < DomainValidation.maxDomains else {
      return showError("Maximum of \(DomainValidation.maxDomains) domains reached")
    }
    guard !domains.contains(trimmed) else { return showError("Domain already exists") }
    guard DomainValidation.isValid(trimmed) else {
      return showError(
        "Enter a valid domain without https:// or www. (e.g., reddit.com)")
    }
    domains.append(trimmed)
    newDomain = ""
  }

  private func remove(_ domain: String) {
    domains.removeAll { $0 == domain }
  }

  private func showError(_ message: String) {
    errorMessage = message
    showingError = true
  }
}

#Preview {
  @Previewable @State var domains: [String] = ["reddit.com", "x.com", "youtube.com"]
  DomainPicker(domains: $domains, isPresented: .constant(true))
}
