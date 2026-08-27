import Foundation

// Composing one of the Little Hours into the ordered pages the reader turns.
//
// Pure and synchronous, so page order, the weekday chapter rotation and the
// seasonal devotion switch are all testable without a view — the same shape
// `ObservedDaysAggregator` uses.

/// The chapter and the collect share the reader's final page.
///
/// Screen 28 is titled "chapter & collect" and shows both together; splitting
/// them would make the office six pages and break the "1 of 5" footer.
/// Everything the page needs is a field here rather than a constant the view
/// must remember to fetch — the collect intro and the faithful-departed
/// prayer are easy to drop otherwise, and neither appears in the mockup.
struct ChapterAndCollect: Equatable {
  let chapter: Chapter
  /// "O Lord hear our prayer" / "And let our cry come unto thee" / "Let us pray".
  let introVersicle: [Versicle]
  /// The hour's own collect(s), then the Collect of the Day, which the rubric
  /// permits in place of any of them.
  let collects: [CollectOption]
  let faithfulDeparted: String
  /// "Let us bless the Lord" / "Thanks be to God".
  let conclusion: [Versicle]
}

/// One screen of the office.
enum OfficePage: Equatable {
  /// Sext only: the Angelus, or the Regina Coeli in its season. The rubric
  /// naming it travels alongside so the page can explain itself.
  case devotion(Devotion, note: String)
  /// The opening versicle, the Gloria that answers it, and the office hymn.
  /// The Gloria is said here *and* after each psalm — the traditional shape of
  /// every hour. The source pages print it only after the psalms, but they
  /// omit other ordinary-of-the-office detail too.
  case opening(responsory: [Versicle], gloria: [Versicle], hymn: Hymn)
  /// `index` is 1-based for display ("Psalm 2 of 3").
  ///
  /// The Gloria closing a psalm carries the *pointed* text — asterisks intact,
  /// exactly as the psalm verses above it are pointed — because it is sung or
  /// said straight on from them. That is a different form from the one that
  /// answers the opening versicle, which is unpointed prose.
  case psalm(Psalm, index: Int, of: Int, gloria: String)
  case chapterAndCollect(ChapterAndCollect)
}

struct OfficeSequence {
  let dataset: LittleHoursDataset
  let calendar: Calendar
  let liturgy: OrdinariateCalendar

  init(
    dataset: LittleHoursDataset = .loadBundled(),
    calendar: Calendar = .current,
    liturgy: OrdinariateCalendar = OrdinariateCalendar()
  ) {
    self.dataset = dataset
    self.calendar = calendar
    self.liturgy = liturgy
  }

  /// The ordered pages for an hour on a day:
  /// `[devotion?] → opening → psalm ×3 → chapterAndCollect`.
  ///
  /// Five pages for Terce and None, six for Sext. Returns an empty array when
  /// the dataset failed to load, so a corrupt bundle shows nothing rather than
  /// trapping mid-prayer.
  func pages(for hour: LittleHour, on date: Date) -> [OfficePage] {
    guard let office = dataset.office(hour) else { return [] }

    var pages: [OfficePage] = []

    if let devotion = devotion(for: office, on: date), let note = office.angelusNote {
      pages.append(.devotion(devotion, note: note))
    }

    pages.append(
      .opening(
        responsory: office.opening,
        gloria: dataset.gloriaVersicles,
        hymn: office.hymn))

    for (offset, psalm) in office.psalms.enumerated() {
      pages.append(
        .psalm(
          psalm,
          index: offset + 1,
          of: office.psalms.count,
          gloria: dataset.gloria))
    }

    if let chapter = office.chapter(forWeekdayIndex: weekdayIndex(of: date)) {
      pages.append(
        .chapterAndCollect(
          ChapterAndCollect(
            chapter: chapter,
            introVersicle: dataset.collectIntroLay,
            collects: collects(for: office, on: date),
            faithfulDeparted: dataset.faithfulDeparted,
            conclusion: dataset.conclusion)))
    }

    return pages
  }

  // MARK: - Rotation and season

  /// 0 = Sunday, matching the dataset's chapter keys. Foundation's `.weekday`
  /// is 1-based from Sunday, so this is simply one less.
  func weekdayIndex(of date: Date) -> Int {
    calendar.component(.weekday, from: date) - 1
  }

  /// The Regina Coeli replaces the Angelus "from Easter Day until the Eve of
  /// Trinity Sunday". Eastertide runs Easter Day → Whitsunday and whitsuntide
  /// Whitsunday → Trinity Sunday, so their union is exactly that span; no
  /// separate date arithmetic is needed, and it stays correct on a day a
  /// principal feast renames, because the season survives that override.
  private func devotion(for office: Office, on date: Date) -> Devotion? {
    guard office.angelus != nil || office.reginaCoeli != nil else { return nil }
    let season = liturgy.day(for: date).season
    let paschal = season == .eastertide || season == .whitsuntide
    return paschal ? office.reginaCoeli : office.angelus
  }

  /// The hour's collect(s) followed by the Collect of the Day — the rubric
  /// under every one of the three hours reads "or the Collect of the Day".
  private func collects(for office: Office, on date: Date) -> [CollectOption] {
    office.collects
      + [
        CollectOption(
          title: "Or the Collect of the Day",
          text: liturgy.day(for: date).collect.text)
      ]
  }
}
