import Foundation

// Presentation logic for the office reader, kept apart from the view so it
// can be asserted directly — the pattern `RuleRowMeta` and `ShieldContent`
// already use in this codebase.

/// What the reader chrome shows for one page.
struct OfficeReaderPage: Equatable {
  /// The hour's name, top left: "Terce", "Sext", "None".
  let headerLeading: String
  /// Context, top right: the day, the psalm's position, or the weekday.
  let headerTrailing: String
  /// The muted line above the action, where the design gives one.
  let footerNote: String?
  /// "Continue" on every page but the last, which is "Amen".
  let actionLabel: String
  let isFinal: Bool
}

/// One block of the final page. Enumerated so tests can assert the *order*
/// of the rite, including the two sections the mockup omits.
struct OfficeFinalSection: Equatable {
  enum Kind: Equatable {
    case chapter
    case chapterVersicle
    case collectIntro
    case collect
    case faithfulDeparted
    case conclusion
  }

  let kind: Kind
  /// A heading where the rite gives one ("The Collect", "Or"), else nil.
  let title: String?
  let body: String
}

enum OfficeReaderModel {

  static func describe(
    _ page: OfficePage,
    at index: Int,
    of total: Int,
    hour: LittleHour,
    on date: Date,
    calendar: Calendar,
    liturgy: OrdinariateCalendar
  ) -> OfficeReaderPage {
    let day = liturgy.day(for: date)
    let isFinal = index == total - 1
    let leading = hourName(hour, liturgy: liturgy)

    switch page {
    case .devotion(let devotion, _):
      return OfficeReaderPage(
        headerLeading: leading,
        headerTrailing: devotion.title,
        footerNote: "Said before the Office.",
        actionLabel: "Continue",
        isFinal: false)

    case .opening:
      return OfficeReaderPage(
        headerLeading: leading,
        headerTrailing: day.dayName,
        footerNote: "\(index + 1) of \(total) · the Psalms follow",
        actionLabel: "Continue",
        isFinal: false)

    case .psalm(_, let position, let count, _):
      return OfficeReaderPage(
        headerLeading: leading,
        headerTrailing: "Psalm \(position) of \(count)",
        footerNote: "The pause is at the asterisk.",
        actionLabel: "Continue",
        isFinal: false)

    case .chapterAndCollect:
      return OfficeReaderPage(
        headerLeading: leading,
        headerTrailing: weekdayName(of: date, calendar: calendar),
        // The conclusion is rendered as a section of the page itself, so the
        // footer carries no separate note.
        footerNote: nil,
        actionLabel: "Amen",
        isFinal: isFinal)
    }
  }

  /// The final page in the order the rite is said. The collect intro and the
  /// faithful-departed prayer are here because the approved scope requires
  /// them — screen 28 shows neither, so this ordering is the guarantee they
  /// are not quietly lost.
  static func finalPageSections(_ final: ChapterAndCollect) -> [OfficeFinalSection] {
    var sections: [OfficeFinalSection] = []

    sections.append(
      OfficeFinalSection(
        kind: .chapter,
        title: "The Chapter · \(final.chapter.reference)",
        body: final.chapter.text))

    sections.append(
      OfficeFinalSection(
        kind: .chapterVersicle,
        title: nil,
        body: "\(final.chapter.versicle)\n\(final.chapter.response)"))

    sections.append(
      OfficeFinalSection(
        kind: .collectIntro,
        title: nil,
        body: final.introVersicle.map(\.text).joined(separator: "\n")))

    for collect in final.collects {
      sections.append(
        OfficeFinalSection(kind: .collect, title: collect.title, body: collect.text))
    }

    sections.append(
      OfficeFinalSection(kind: .faithfulDeparted, title: nil, body: final.faithfulDeparted))

    sections.append(
      OfficeFinalSection(
        kind: .conclusion,
        title: nil,
        body: final.conclusion.map(\.text).joined(separator: " ")))

    return sections
  }

  /// "Terce" / "Sext" / "None", from the dataset rather than the enum case —
  /// the case for None is spelled `nones` to dodge `Optional.none`.
  static func hourName(
    _ hour: LittleHour,
    dataset: LittleHoursDataset = .loadBundled(),
    liturgy: OrdinariateCalendar = OrdinariateCalendar()
  ) -> String {
    dataset.office(hour)?.latin ?? hour.rawValue.capitalized
  }

  static func weekdayName(of date: Date, calendar: Calendar) -> String {
    let formatter = DateFormatter()
    formatter.calendar = calendar
    formatter.timeZone = calendar.timeZone
    formatter.dateFormat = "EEEE"
    return formatter.string(from: date)
  }
}

/// The reader's one side effect: finishing the office.
///
/// Recording alone is not enough — without the reschedule, an hour prayed
/// early still gets its notice at the appointed time, contradicting screen
/// 29's "dismissed by praying it".
struct OfficeCompletion {
  var store: KeptHoursStore = KeptHoursStore()
  var reschedule: () -> Void = { OfficeNotificationScheduler().reschedule() }

  /// - Parameters:
  ///   - day: the day the reader was opened for, not the current date.
  ///   - time: when Amen was tapped, which may fall on a later day.
  func amen(_ hour: LittleHour, on day: Date, at time: Date = Date()) {
    store.record(hour, on: day, at: time)
    reschedule()
  }
}
