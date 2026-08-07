import Foundation

/// A fixed month/day pair (calendar-year anchor).
struct MonthDay: Equatable, Hashable, Comparable {
  let month: Int
  let day: Int

  static func < (lhs: MonthDay, rhs: MonthDay) -> Bool {
    (lhs.month, lhs.day) < (rhs.month, rhs.day)
  }
}

enum LiturgicalSeason: String, Codable {
  case advent
  case christmastide
  case epiphanytide
  case preLent
  case lent
  case holyWeek
  case eastertide
  case whitsuntide
  case trinitytide
}

struct Collect: Equatable {
  /// Short source label, e.g. "Trinity IX" or "All Saints' Day".
  let title: String
  let text: String
}

/// Resolution of a civil date against the Ordinariate kalendar.
struct LiturgicalDay: Equatable {
  /// e.g. "Friday after Trinity IX", "Christ the King", "Christmas Day".
  let dayName: String
  let season: LiturgicalSeason
  /// e.g. "Commemoration of S. Sixtus II, Bishop & Martyr" (nil when none).
  let commemorationText: String?
  let collect: Collect
}

// MARK: - Dataset (bundled JSON)

struct LiturgicalDataset: Decodable {
  struct Feast: Decodable {
    let month: Int
    let day: Int
    let name: String
    /// "principal" renames the day and provides its collect;
    /// "commemoration" adds a commemoration line only.
    let rank: String
    let collect: String?
  }

  let sanctorale: [Feast]
  /// Keyed collects: advent1…advent4, christmas, christmas1, christmas2,
  /// epiphany, epiphany1…epiphany6, septuagesima, sexagesima,
  /// quinquagesima, ashWednesday, lent1…lent5, palmSunday, easterDay,
  /// easter1…easter5, ascension, sundayAfterAscension, whitsunday,
  /// trinitySunday, trinity1…trinity24, christTheKing.
  let temporale: [String: String]

  static func loadBundled() -> LiturgicalDataset {
    // Bundle.main resolves to the host bundle in the app, the extension
    // bundle in SapientiaShieldConfig (the JSON is a member of both), and
    // the app bundle under TEST_HOST.
    guard
      let url = Bundle.main.url(
        forResource: "ordinariate-calendar", withExtension: "json"),
      let data = try? Data(contentsOf: url),
      let dataset = try? JSONDecoder().decode(LiturgicalDataset.self, from: data)
    else {
      return LiturgicalDataset(sanctorale: [], temporale: [:])
    }
    return dataset
  }
}
