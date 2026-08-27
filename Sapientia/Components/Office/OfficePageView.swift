import SwiftUI

/// One page of the office, on the steel ground.
///
/// Every colour here is fixed rather than appearance-aware: the rite reads
/// light-on-steel in both light and dark mode, by design
/// (`SapientiaTheme.swift`). Do not swap these for `SapientiaTheme.text`.
///
/// Every multi-line `Text` here carries `.fullyLaidOut()`. Without it SwiftUI
/// treats prose as compressible and truncates it with an ellipsis when a
/// sibling wants the space — which is precisely how None's collect lost its
/// last clause ("who livest and reignest…") before this was added, and the
/// same defect that shipped in the onboarding steps at `b5daecb`.
extension View {
  /// Never compress this text vertically; give it the height it asks for.
  func fullyLaidOut() -> some View {
    fixedSize(horizontal: false, vertical: true)
  }
}

struct OfficePageView: View {
  let page: OfficePage

  var body: some View {
    switch page {
    case .devotion(let devotion, let note):
      devotionPage(devotion, note: note)
    case .opening(let responsory, let gloria, let hymn):
      openingPage(responsory: responsory, gloria: gloria, hymn: hymn)
    case .psalm(let psalm, _, _, let gloria):
      psalmPage(psalm, gloria: gloria)
    case .chapterAndCollect(let final):
      finalPage(final)
    }
  }

  // MARK: - Devotion (Sext only)

  private func devotionPage(_ devotion: Devotion, note: String) -> some View {
    VStack(alignment: .leading, spacing: SapientiaTheme.space6) {
      kicker(devotion.title)

      Text(note)
        .font(.sapientiaBody(13))
        .lineSpacing(3)
        .foregroundColor(SapientiaTheme.onDark(0.45))
        .fullyLaidOut()

      VStack(alignment: .leading, spacing: SapientiaTheme.space3) {
        ForEach(Array(devotion.lines.enumerated()), id: \.offset) { _, line in
          versicleLine(line)
        }
      }

      rule()

      Text(devotion.collect)
        .font(.sapientiaDisplay(20))
        .lineSpacing(5)
        .foregroundColor(SapientiaTheme.onDark())
        .fullyLaidOut()
    }
  }

  // MARK: - Opening: responsory and hymn

  private func openingPage(responsory: [Versicle], gloria: [Versicle], hymn: Hymn) -> some View {
    VStack(alignment: .leading, spacing: SapientiaTheme.space6) {
      VStack(alignment: .leading, spacing: SapientiaTheme.space3) {
        kicker("The Responsory")
        // The Gloria answers the opening versicle and is said straight on from
        // it, so it is set in the same voice — one continuous responsory, not
        // a separate labelled block. (After a psalm it *is* labelled, because
        // there it stands on its own rather than completing a versicle.)
        ForEach(Array((responsory + gloria).enumerated()), id: \.offset) { _, line in
          Text(line.text)
            .font(.sapientiaDisplay(24))
            .lineSpacing(6)
            // The officiant leads, the people answer: the response sits back.
            .foregroundColor(SapientiaTheme.onDark(line.speaker == "People" ? 0.70 : 1.0))
            .fullyLaidOut()
        }
      }

      rule()

      VStack(alignment: .leading, spacing: SapientiaTheme.space4) {
        kicker("Office Hymn · \(hymn.latin)")
        ForEach(Array(hymn.verses.enumerated()), id: \.offset) { _, verse in
          Text(verse)
            .font(.sapientiaBody(17))
            .lineSpacing(6)
            .foregroundColor(SapientiaTheme.onDark())
            .fullyLaidOut()
        }
        Text(hymn.note)
          .font(.sapientiaBody(13))
          .foregroundColor(SapientiaTheme.onDark(0.45))
          .fullyLaidOut()
          .padding(.top, SapientiaTheme.space2)
      }
    }
  }

  // MARK: - A psalm

  private func psalmPage(_ psalm: Psalm, gloria: String) -> some View {
    VStack(alignment: .leading, spacing: SapientiaTheme.space4) {
      kicker("\(psalm.number) · \(psalm.latin)")

      VStack(alignment: .leading, spacing: SapientiaTheme.space2) {
        ForEach(Array(psalm.verses.enumerated()), id: \.offset) { index, verse in
          Text(verse)
            .font(.sapientiaDisplay(22))
            .lineSpacing(4)
            // The opening verse carries the psalm; the rest follow it.
            .foregroundColor(SapientiaTheme.onDark(index == 0 ? 1.0 : 0.78))
            .fullyLaidOut()
        }
      }

      // The Gloria closes the psalm in the same pointed form: no speaker
      // labels, asterisks kept, set like the verses above it but stepped back
      // so the psalm proper still leads the page.
      VStack(alignment: .leading, spacing: SapientiaTheme.space2) {
        ForEach(Array(gloria.split(separator: "\n").enumerated()), id: \.offset) { _, line in
          Text(String(line))
            .font(.sapientiaDisplay(22))
            .lineSpacing(4)
            .foregroundColor(SapientiaTheme.onDark(0.62))
            .fullyLaidOut()
        }
      }
      .padding(.top, SapientiaTheme.space3)
    }
  }

  // MARK: - Chapter and collect

  private func finalPage(_ final: ChapterAndCollect) -> some View {
    VStack(alignment: .leading, spacing: SapientiaTheme.space6) {
      ForEach(Array(OfficeReaderModel.finalPageSections(final).enumerated()), id: \.offset) {
        _, section in
        section.view
      }
    }
  }

  // MARK: - Shared pieces

  private func kicker(_ text: String) -> some View {
    Text(text)
      .font(.sapientiaHeading(13))
      .kerning(2.0)
      .textCase(.uppercase)
      .foregroundColor(SapientiaTheme.accent300)
      .fullyLaidOut()
  }

  private func versicleLine(_ line: Versicle) -> some View {
    HStack(alignment: .firstTextBaseline, spacing: SapientiaTheme.space2) {
      if !line.speaker.isEmpty {
        Text(line.speaker)
          .font(.sapientiaHeading(13))
          .foregroundColor(SapientiaTheme.accent300)
          .fullyLaidOut()
          .frame(width: 22, alignment: .leading)
      }
      Text(line.text)
        .font(.sapientiaBody(16))
        .lineSpacing(4)
        .foregroundColor(SapientiaTheme.onDark(line.speaker == "R" ? 0.72 : 1.0))
        .fullyLaidOut()
      Spacer(minLength: 0)
    }
  }

  private func rule() -> some View {
    Rectangle()
      .fill(SapientiaTheme.onDark(0.16))
      .frame(height: 1)
  }
}

// MARK: - Rendering a final-page section

extension OfficeFinalSection {
  @ViewBuilder
  var view: some View {
    switch kind {
    case .chapter:
      VStack(alignment: .leading, spacing: SapientiaTheme.space3) {
        if let title {
          Text(title)
            .font(.sapientiaHeading(13))
            .kerning(2.0)
            .textCase(.uppercase)
            .foregroundColor(SapientiaTheme.accent300)
            .fullyLaidOut()
        }
        Text(body)
          .font(.sapientiaBody(17))
          .lineSpacing(6)
          .foregroundColor(SapientiaTheme.onDark())
          .fullyLaidOut()
      }

    case .chapterVersicle:
      Text(body)
        .font(.sapientiaDisplay(19))
        .lineSpacing(4)
        .foregroundColor(SapientiaTheme.onDark(0.85))
        .fullyLaidOut()

    case .collectIntro:
      Text(body)
        .font(.sapientiaBody(15))
        .lineSpacing(4)
        .foregroundColor(SapientiaTheme.onDark(0.62))
        .fullyLaidOut()

    case .collect:
      VStack(alignment: .leading, spacing: SapientiaTheme.space2) {
        if let title {
          Text(title)
            .font(.sapientiaHeading(13))
            .kerning(2.0)
            .textCase(.uppercase)
            .foregroundColor(SapientiaTheme.accent300)
            .fullyLaidOut()
        }
        Text(body)
          .font(.sapientiaDisplay(23))
          .lineSpacing(5)
          .foregroundColor(SapientiaTheme.onDark())
          .fullyLaidOut()
      }

    case .faithfulDeparted:
      Text(body)
        .font(.sapientiaBody(15))
        .lineSpacing(4)
        .foregroundColor(SapientiaTheme.onDark(0.62))
        .fullyLaidOut()

    case .conclusion:
      Text(body)
        .font(.sapientiaBody(15))
        .lineSpacing(4)
        .foregroundColor(SapientiaTheme.onDark(0.85))
        .fullyLaidOut()
    }
  }
}
