import Foundation

/// Pure domain-string validation + normalization, extracted from
/// `DomainPicker` so the rules are testable and shared.
enum DomainValidation {
  static let maxDomains = 50

  static func normalize(_ raw: String) -> String {
    raw.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
  }

  static func isValid(_ domain: String) -> Bool {
    let domainRegex =
      #"^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"#
    let predicate = NSPredicate(format: "SELF MATCHES %@", domainRegex)

    guard domain.count <= 253 else { return false }
    guard !domain.hasPrefix(".") && !domain.hasSuffix(".") else { return false }
    guard !domain.contains("..") else { return false }
    guard domain.contains(".") else { return false }

    return predicate.evaluate(with: domain)
  }
}
