import SwiftUI

/// A third-party component Sapientia depends on, with its license notice.
struct Acknowledgement: Identifiable {
  var id: String { name }
  let name: String
  let summary: String
  /// Short license name, e.g. "MIT License". `nil` for a plain attribution.
  let licenseName: String?
  /// The full notice to reproduce (kept verbatim to satisfy the license).
  let licenseText: String?
  let url: String?
}

/// The credits shown in Settings → About → Acknowledgements. Reproducing the
/// MIT and OFL notices here is the one obligation those licenses place on a
/// binary distribution (TestFlight / App Store).
enum Acknowledgements {
  static let all: [Acknowledgement] = [
    Acknowledgement(
      name: "Foqos",
      summary:
        "Sapientia began as a fork of Foqos by Ali Waseem, an open-source NFC/QR app blocker.",
      licenseName: "MIT License",
      licenseText: """
        MIT License

        Copyright (c) 2024 Ali Waseem

        Permission is hereby granted, free of charge, to any person obtaining a \
        copy of this software and associated documentation files (the \
        "Software"), to deal in the Software without restriction, including \
        without limitation the rights to use, copy, modify, merge, publish, \
        distribute, sublicense, and/or sell copies of the Software, and to \
        permit persons to whom the Software is furnished to do so, subject to \
        the following conditions:

        The above copyright notice and this permission notice shall be included \
        in all copies or substantial portions of the Software.

        THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS \
        OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF \
        MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. \
        IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY \
        CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, \
        TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE \
        SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
        """,
      url: "https://github.com/awaseem/foqos"
    ),
    Acknowledgement(
      name: "Barlow & Barlow Condensed",
      summary: "The typefaces used throughout Sapientia.",
      licenseName: "SIL Open Font License 1.1",
      licenseText: """
        Copyright (c) 2017 The Barlow Project Authors \
        (https://github.com/jpt/barlow)

        This Font Software is licensed under the SIL Open Font License, \
        Version 1.1. This license is available with a FAQ at: \
        https://openfontlicense.org
        """,
      url: "https://fonts.google.com/specimen/Barlow"
    ),
    Acknowledgement(
      name: "Daily Office texts",
      summary:
        "The Collects and prayers follow the tradition made available at prayer.covert.org.",
      licenseName: nil,
      licenseText: nil,
      url: "http://prayer.covert.org/"
    ),
  ]
}

/// Settings → About → Acknowledgements. Blueprint sections, one per credit.
struct AcknowledgementsView: View {
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    BlueprintStage(
      title: "Acknowledgements",
      leadingLabel: "Done",
      leadingAction: { dismiss() }
    ) {
      VStack(alignment: .leading, spacing: SapientiaTheme.space8) {
        Text(
          "Sapientia stands on open-source work. Their notices are reproduced here in full."
        )
        .font(.sapientiaBody(15))
        .lineSpacing(3)
        .foregroundColor(SapientiaTheme.text.opacity(0.62))

        ForEach(Acknowledgements.all) { credit in
          section(for: credit)
        }
      }
    }
  }

  private func section(for credit: Acknowledgement) -> some View {
    BlueprintFormSection(title: credit.name) {
      VStack(alignment: .leading, spacing: SapientiaTheme.space3) {
        Text(credit.summary)
          .font(.sapientiaBody(15))
          .lineSpacing(3)
          .foregroundColor(SapientiaTheme.text.opacity(0.62))
          .padding(.top, SapientiaTheme.space3)

        if let licenseName = credit.licenseName {
          Text(licenseName).sapientiaKicker()
        }

        if let licenseText = credit.licenseText {
          BlueprintCard {
            Text(licenseText)
              .font(.sapientiaBody(12))
              .lineSpacing(3)
              .foregroundColor(SapientiaTheme.text.opacity(0.7))
              .fixedSize(horizontal: false, vertical: true)
          }
        }

        if let url = credit.url, let link = URL(string: url) {
          Link(destination: link) {
            BlueprintListRow(title: url.replacingOccurrences(of: "https://", with: "")) {
              Image(systemName: "arrow.up.right")
                .font(.caption)
                .foregroundColor(SapientiaTheme.text.opacity(0.4))
            }
          }
          .buttonStyle(.plain)
        }
      }
    }
  }
}

#Preview {
  AcknowledgementsView()
}
