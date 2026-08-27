import SwiftUI

/// The office itself — screens 26–28 and 30.
///
/// The reader owns its chrome rather than using `BlueprintStage`: the utility
/// stages centre a title between a Cancel and a Done, while the rite's header
/// is two uppercase kickers, the hour and the day, with nothing between them.
/// The ground, spacing and type all still come from `SapientiaTheme`.
struct OfficeReaderView: View {
  let hour: LittleHour
  /// The day the office is being prayed for. Recorded against this, never
  /// against `Date()` at Amen time.
  var day: Date = Date()

  var sequence: OfficeSequence = OfficeSequence()
  var completion: OfficeCompletion = OfficeCompletion()
  var liturgy: OrdinariateCalendar = OrdinariateCalendar()
  var calendar: Calendar = .current

  @Environment(\.dismiss) private var dismiss
  @State private var pageIndex = 0

  private var pages: [OfficePage] {
    sequence.pages(for: hour, on: day)
  }

  private var current: OfficeReaderPage? {
    guard pageIndex < pages.count else { return nil }
    return OfficeReaderModel.describe(
      pages[pageIndex], at: pageIndex, of: pages.count,
      hour: hour, on: day, calendar: calendar, liturgy: liturgy)
  }

  var body: some View {
    ZStack {
      SapientiaTheme.accent900.ignoresSafeArea()

      if let current, pageIndex < pages.count {
        VStack(spacing: 0) {
          header(current)

          ScrollView(showsIndicators: false) {
            OfficePageView(page: pages[pageIndex])
              .padding(.horizontal, SapientiaTheme.space8)
              .padding(.top, SapientiaTheme.space6)
              .padding(.bottom, SapientiaTheme.space8)
              .frame(maxWidth: .infinity, alignment: .leading)
          }
          // A new page starts at its beginning, not where the last one was
          // scrolled to.
          .id(pageIndex)

          footer(current)
        }
      } else {
        // The bundle failed to load. Say so plainly rather than showing an
        // empty steel field with no way out.
        unavailable
      }
    }
  }

  // MARK: - Chrome

  private func header(_ page: OfficeReaderPage) -> some View {
    HStack(alignment: .firstTextBaseline) {
      // Screens 26–30 show no way out of the office. In a full-screen cover
      // that would strand the user, and the plan requires leaving early to be
      // possible (it records nothing), so a hairline dismiss is added here.
      Button {
        dismiss()
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 13, weight: .light))
          .foregroundColor(SapientiaTheme.onDark(0.55))
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Leave the office")

      Text(page.headerLeading)
        .font(.sapientiaHeading(13))
        .kerning(2.1)
        .textCase(.uppercase)
        .foregroundColor(SapientiaTheme.onDark(0.65))
        .padding(.leading, SapientiaTheme.space3)

      Spacer(minLength: SapientiaTheme.space4)

      Text(page.headerTrailing)
        .font(.sapientiaHeading(13))
        .kerning(1.3)
        .textCase(.uppercase)
        .foregroundColor(SapientiaTheme.onDark(0.45))
        .multilineTextAlignment(.trailing)
    }
    .padding(.horizontal, SapientiaTheme.space8)
    .padding(.top, SapientiaTheme.space6)
    .padding(.bottom, SapientiaTheme.space4)
  }

  @ViewBuilder
  private func footer(_ page: OfficeReaderPage) -> some View {
    VStack(alignment: .leading, spacing: SapientiaTheme.space4) {
      Rectangle()
        .fill(SapientiaTheme.onDark(0.16))
        .frame(height: 1)

      if page.isFinal {
        Button("Amen") { finish() }
          .buttonStyle(BlueprintPrimaryButtonStyle())
          .padding(.horizontal, SapientiaTheme.space8)
          .padding(.top, SapientiaTheme.space2)
      } else {
        HStack(alignment: .center, spacing: SapientiaTheme.space4) {
          if let note = page.footerNote {
            Text(note)
              .font(.sapientiaBody(14))
              .foregroundColor(SapientiaTheme.onDark(0.55))
          }
          Spacer(minLength: 0)
          Button(page.actionLabel) { advance() }
            .buttonStyle(
              BlueprintSecondaryButtonStyle(
                foreground: SapientiaTheme.paper,
                borderColor: SapientiaTheme.onDark(0.45)))
        }
        .padding(.horizontal, SapientiaTheme.space8)
      }
    }
    .padding(.bottom, SapientiaTheme.space6)
  }

  private var unavailable: some View {
    VStack(spacing: SapientiaTheme.space4) {
      Text("The office is unavailable.")
        .font(.sapientiaHeading(20))
        .foregroundColor(SapientiaTheme.onDark())
      Text("Its texts could not be read from the app bundle.")
        .font(.sapientiaBody(15))
        .foregroundColor(SapientiaTheme.onDark(0.62))
      Button("Close") { dismiss() }
        .buttonStyle(
          BlueprintSecondaryButtonStyle(
            foreground: SapientiaTheme.paper,
            borderColor: SapientiaTheme.onDark(0.45))
        )
        .padding(.top, SapientiaTheme.space4)
    }
    .padding(SapientiaTheme.space8)
    .multilineTextAlignment(.center)
  }

  // MARK: - Actions

  private func advance() {
    guard pageIndex < pages.count - 1 else { return }
    withAnimation(.easeInOut(duration: 0.18)) {
      pageIndex += 1
    }
  }

  private func finish() {
    completion.amen(hour, on: day, at: Date())
    dismiss()
  }
}

#Preview {
  OfficeReaderView(hour: .terce)
}
