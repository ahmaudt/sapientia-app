import Foundation

// The Little Hours — Terce, Sext and None — as bundled with the app.
//
// Every text ships in `little-hours.json`; nothing is fetched. That file is
// generated from `scripts/liturgy/offices-data.js` and
// `scripts/liturgy/devotions.json` by `scripts/liturgy/build-little-hours.mjs`,
// so no liturgical text is retyped by hand. Edit the sources, re-run the
// generator, and let `scripts/diff-office-text.py` prove they still agree.

/// One of the three daytime offices.
///
/// The raw values match the JSON keys and the notification identifiers. The
/// case for None is spelled `nones` deliberately: a case literally named
/// `none` collides with `Optional.none` at every `LittleHour?` use site, which
/// Swift resolves to the optional and only warns about. The office is still
/// displayed as "None" — that string comes from the dataset's `latin` field,
/// never from the case name.
enum LittleHour: String, CaseIterable, Codable, Hashable {
  case terce
  case sext
  case nones = "none"
}

/// A said line with its speaker — "Officiant"/"People" in the offices,
/// "V"/"R" in the devotions, and empty for an antiphon's own lines.
struct Versicle: Decodable, Equatable {
  let speaker: String
  let text: String
}

struct Hymn: Decodable, Equatable {
  let latin: String
  let note: String
  let verses: [String]
}

struct Psalm: Decodable, Equatable {
  /// e.g. "Psalm 121".
  let number: String
  /// The Latin incipit, e.g. "Levavi oculos".
  let latin: String
  /// Verses with their mid-verse `*` intact — the asterisk marks the pause.
  let verses: [String]
}

/// The short scripture read at the hour, with its versicle and response.
/// Rotates by day of week; the psalms and hymn do not.
struct Chapter: Decodable, Equatable {
  let reference: String
  let text: String
  let versicle: String
  let response: String
}

struct CollectOption: Decodable, Equatable {
  /// "The Collect", or "Or" for an alternate.
  let title: String
  let text: String
}

/// The Angelus or the Regina Coeli, said before Sext.
struct Devotion: Decodable, Equatable {
  let title: String
  let lines: [Versicle]
  let collect: String
}

struct Office: Decodable, Equatable {
  let key: String
  /// "Terce", "Sext", "None" — the display name.
  let latin: String
  /// "Midmorning Prayer".
  let name: String
  /// "The Third Hour".
  let hour: String
  /// "09:00" — the traditional time, and the reminder default.
  let defaultTime: String
  let opening: [Versicle]
  let hymn: Hymn
  let psalms: [Psalm]
  /// Keyed "0"…"6", 0 = Sunday, matching `Calendar.component(.weekday)` - 1.
  let chapters: [String: Chapter]
  let collects: [CollectOption]
  /// Present on Sext alone: the rubric naming the devotion said beforehand.
  let angelusNote: String?
  let angelus: Devotion?
  let reginaCoeli: Devotion?

  /// The chapter for a weekday index (0 = Sunday).
  func chapter(forWeekdayIndex index: Int) -> Chapter? {
    chapters[String(index)]
  }

  /// "Psalms 120, 121, 122" — used in row captions and notification bodies,
  /// so the numbers are never hardcoded at a call site.
  var psalmSummary: String {
    let numbers = psalms.map { $0.number.replacingOccurrences(of: "Psalm ", with: "") }
    return "Psalms " + numbers.joined(separator: ", ")
  }

  /// "Midmorning — Terce", the notification title and row heading. The
  /// dataset stores "Midmorning Prayer"; the screens drop the "Prayer".
  var displayTitle: String {
    let shortName = name.replacingOccurrences(of: " Prayer", with: "")
    return "\(shortName) — \(latin)"
  }

  /// "The third hour" — sentence case, as screens 25 and 29 write it. The
  /// dataset stores the title-cased "The Third Hour".
  var hourPhrase: String {
    let lowered = hour.lowercased()
    guard let first = lowered.first else { return lowered }
    return first.uppercased() + lowered.dropFirst()
  }
}

/// The bundled dataset: three offices plus the texts they share.
struct LittleHoursDataset: Decodable, Equatable {
  /// The Gloria Patri as one pointed block, `*` marking the chant pause.
  /// Retained so `scripts/diff-office-text.py` can verify it against source;
  /// the office renders `gloriaVersicles` instead.
  let gloria: String
  /// The Gloria said as a responsory: the officiant begins, the people answer.
  let gloriaVersicles: [Versicle]
  /// The lay form of the versicle before the collect. The priest/deacon form
  /// ("The Lord be with you") is not shipped — see the plan's Open Questions.
  let collectIntroLay: [Versicle]
  let conclusion: [Versicle]
  let faithfulDeparted: String
  let offices: [String: Office]

  static let empty = LittleHoursDataset(
    gloria: "", gloriaVersicles: [], collectIntroLay: [], conclusion: [],
    faithfulDeparted: "", offices: [:])

  func office(_ hour: LittleHour) -> Office? {
    offices[hour.rawValue]
  }

  /// Decode, falling back to `.empty` rather than trapping. Mirrors
  /// `LiturgicalDataset.loadBundled()`: a missing or corrupt resource must
  /// degrade, never crash a user mid-prayer.
  static func decode(from data: Data) -> LittleHoursDataset {
    (try? JSONDecoder().decode(LittleHoursDataset.self, from: data)) ?? .empty
  }

  /// `Bundle.main` resolves to the host app bundle, and to the app bundle
  /// under TEST_HOST. The office JSON is intentionally *not* a member of the
  /// shield extension — the shield shows a prayer, not an office.
  static func loadBundled() -> LittleHoursDataset {
    guard
      let url = Bundle.main.url(forResource: "little-hours", withExtension: "json"),
      let data = try? Data(contentsOf: url)
    else {
      return .empty
    }
    return decode(from: data)
  }
}
