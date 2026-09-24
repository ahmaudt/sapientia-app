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

/// Rank of a sanctorale observance, as the Ordinariate ORDO gives it.
enum ObservanceRank: String, Decodable {
  case solemnity
  case feast
  case memorial
  case optionalMemorial

  /// Higher wins when several observances share a date.
  var precedence: Int {
    switch self {
    case .solemnity: return 3
    case .feast: return 2
    case .memorial: return 1
    case .optionalMemorial: return 0
    }
  }
}

/// The observance that governs a day: a saint or feast from the sanctorale,
/// or Ascension Day from the temporale.
struct Observance: Equatable {
  let name: String
  let rank: ObservanceRank
  var isFeastOfTheLord = false
  /// Replaces the generated phrase wholesale, for names that already say what
  /// the day is ("Christmas Day", "Ascension Day").
  var noticeName: String?

  /// "the memorial of S. Dominic, Priest", "the Feast of the Transfiguration
  /// of Our Lord". An optional memorial reads as a memorial: that it is
  /// optional is a rubric, not news.
  func phrase(capitalized: Bool) -> String {
    if let noticeName { return noticeName }
    let kind: String
    switch rank {
    case .solemnity: kind = "Solemnity"
    case .feast: kind = "Feast"
    case .memorial, .optionalMemorial: kind = "memorial"
    }
    let article = capitalized ? "The" : "the"
    let subject = name.hasPrefix("The ") ? "the " + name.dropFirst(4) : name
    return "\(article) \(kind) of \(subject)"
  }
}

/// Resolution of a civil date against the Ordinariate kalendar.
struct LiturgicalDay: Equatable {
  /// e.g. "Friday after Trinity IX", "Christ the King", "Christmas Day".
  let dayName: String
  let season: LiturgicalSeason
  /// The line beneath the day's name when a memorial governs it, e.g. "The
  /// memorial of S. Dominic, Priest". Nil otherwise — including when a saint
  /// falls on a day that outranks it, since that saint is not kept.
  let commemorationText: String?
  let collect: Collect
  /// What governs the day, when anything but the temporale does.
  var observance: Observance? = nil
}

// MARK: - Dataset (bundled JSON)

struct LiturgicalDataset: Decodable {
  struct Feast: Decodable {
    let month: Int
    let day: Int
    let name: String
    let rank: ObservanceRank
    /// A Feast of the Lord keeps precedence over an ordinary Sunday, where
    /// any other feast is abrogated.
    let isFeastOfTheLord: Bool
    let collect: String?
    /// Book and page or section the collect was copied from.
    let collectSource: String?
    let noticeName: String?

    init(
      month: Int, day: Int, name: String, rank: ObservanceRank,
      isFeastOfTheLord: Bool = false, collect: String? = nil,
      collectSource: String? = nil, noticeName: String? = nil
    ) {
      self.month = month
      self.day = day
      self.name = name
      self.rank = rank
      self.isFeastOfTheLord = isFeastOfTheLord
      self.collect = collect
      self.collectSource = collectSource
      self.noticeName = noticeName
    }

    private enum CodingKeys: String, CodingKey {
      case month, day, name, rank, collect, collectSource, noticeName
      case isFeastOfTheLord = "lordFeast"
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      self.init(
        month: try container.decode(Int.self, forKey: .month),
        day: try container.decode(Int.self, forKey: .day),
        name: try container.decode(String.self, forKey: .name),
        rank: try container.decode(ObservanceRank.self, forKey: .rank),
        isFeastOfTheLord: try container.decodeIfPresent(Bool.self, forKey: .isFeastOfTheLord)
          ?? false,
        collect: try container.decodeIfPresent(String.self, forKey: .collect),
        collectSource: try container.decodeIfPresent(String.self, forKey: .collectSource),
        noticeName: try container.decodeIfPresent(String.self, forKey: .noticeName))
    }

    var observance: Observance {
      Observance(
        name: name, rank: rank, isFeastOfTheLord: isFeastOfTheLord, noticeName: noticeName)
    }
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
