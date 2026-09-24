import Foundation

/// Maps civil dates onto the Ordinariate (Divine Worship / Anglican
/// patrimony) kalendar: seasons, Sunday names in the Trinity reckoning,
/// fixed feasts, and the Collect governing each day. Fully offline; the
/// sanctorale and collect texts come from a bundled JSON dataset.
struct OrdinariateCalendar {
  let dataset: LiturgicalDataset
  let gregorian: Calendar

  init(
    dataset: LiturgicalDataset = .loadBundled(),
    calendar: Calendar = Calendar(identifier: .gregorian)
  ) {
    self.dataset = dataset
    self.gregorian = calendar
  }

  // MARK: - Easter computus (Anonymous Gregorian algorithm)

  static func easter(year: Int) -> MonthDay {
    let a = year % 19
    let b = year / 100
    let c = year % 100
    let d = b / 4
    let e = b % 4
    let f = (b + 8) / 25
    let g = (b - f + 1) / 3
    let h = (19 * a + b - d - g + 15) % 30
    let i = c / 4
    let k = c % 4
    let l = (32 + 2 * e + 2 * i - h - k) % 7
    let m = (a + 11 * h + 22 * l) / 451
    let month = (h + l - 7 * m + 114) / 31
    let day = ((h + l - 7 * m + 114) % 31) + 1
    return MonthDay(month: month, day: day)
  }

  // MARK: - Public API

  func day(for date: Date) -> LiturgicalDay {
    let noon = normalize(date)
    let year = gregorian.component(.year, from: noon)
    let anchors = Anchors(year: year, calendar: gregorian)

    let seasonalDay = seasonal(for: noon, anchors: anchors)
    let temporal = LiturgicalDay(
      dayName: seasonalDay.dayName,
      season: seasonalDay.season,
      commemorationText: nil,
      collect: seasonalDay.collect)

    // Ascension Day is the one temporale day that carries an observance of
    // its own, so "feasts only" reminders and the evening notice keep it.
    if gregorian.isDate(noon, inSameDayAs: anchors.ascension) {
      return LiturgicalDay(
        dayName: temporal.dayName, season: temporal.season, commemorationText: nil,
        collect: temporal.collect,
        observance: Observance(
          name: "Ascension Day", rank: .solemnity, isFeastOfTheLord: true,
          noticeName: "Ascension Day"))
    }

    guard !isProtected(noon, anchors: anchors),
      let entry = governingEntry(for: noon)
    else { return temporal }

    // Sundays: only a Solemnity or a Feast of the Lord displaces an ordinary
    // Sunday — any lesser observance is abrogated for the year — and nothing
    // displaces a Sunday of Advent or Lent. Feast transfer is not modeled.
    if isSunday(noon) {
      let isPenitentialSunday = seasonalDay.season == .advent || seasonalDay.season == .lent
      let outranksSunday = entry.rank == .solemnity || entry.isFeastOfTheLord
      if isPenitentialSunday || !outranksSunday { return temporal }
    }

    let collect = Collect(title: entry.name, text: entry.collect ?? seasonalDay.collect.text)
    switch entry.rank {
    case .solemnity, .feast:
      // A feast renames the day.
      return LiturgicalDay(
        dayName: entry.name, season: seasonalDay.season, commemorationText: nil,
        collect: collect, observance: entry.observance)
    case .memorial, .optionalMemorial:
      // A memorial keeps the temporal name and adds its own line beneath it.
      return LiturgicalDay(
        dayName: seasonalDay.dayName, season: seasonalDay.season,
        commemorationText: entry.observance.phrase(capitalized: true),
        collect: collect, observance: entry.observance)
    }
  }

  // MARK: - Sanctorale

  /// Days on which the temporale governs and no saint is kept or named:
  /// Holy Week, Easter Day through the Saturday of its octave, and Ash
  /// Wednesday. (Ascension Day is handled before this is consulted.)
  private func isProtected(_ date: Date, anchors: Anchors) -> Bool {
    let octaveEnd = gregorian.date(byAdding: .day, value: 7, to: anchors.easter)!
    return (date >= anchors.palmSunday && date < octaveEnd)
      || gregorian.isDate(date, inSameDayAs: anchors.ashWednesday)
  }

  /// The highest-ranked entry on the date; between equal ranks, the first
  /// listed.
  private func governingEntry(for date: Date) -> LiturgicalDataset.Feast? {
    let md = monthDay(date)
    var best: LiturgicalDataset.Feast?
    for entry in dataset.sanctorale where entry.month == md.month && entry.day == md.day {
      if entry.rank.precedence > (best?.rank.precedence ?? -1) {
        best = entry
      }
    }
    return best
  }

  // MARK: - Collect lookup

  func keyedCollect(_ key: String, title: String) -> Collect {
    Collect(title: title, text: dataset.temporale[key] ?? "")
  }

  // MARK: - Date helpers

  private func normalize(_ date: Date) -> Date {
    var components = gregorian.dateComponents([.year, .month, .day], from: date)
    components.hour = 12
    return gregorian.date(from: components) ?? date
  }

  func monthDay(_ date: Date) -> MonthDay {
    let c = gregorian.dateComponents([.month, .day], from: date)
    return MonthDay(month: c.month!, day: c.day!)
  }

  func isSunday(_ date: Date) -> Bool {
    gregorian.component(.weekday, from: date) == 1
  }

  func weekdayName(_ date: Date) -> String {
    let symbols = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]
    return symbols[gregorian.component(.weekday, from: date) - 1]
  }

  enum WeekdayStyle { case after }

  func weekdayPrefixed(
    _ date: Date, base: String, style: WeekdayStyle = .after
  ) -> String {
    isSunday(date) ? base : "\(weekdayName(date)) after \(base)"
  }

  func previousSunday(_ date: Date) -> Date {
    let weekday = gregorian.component(.weekday, from: date)
    return gregorian.date(byAdding: .day, value: -(weekday - 1), to: date)!
  }

  func weeksBetween(_ start: Date, _ end: Date) -> Int {
    let days = gregorian.dateComponents([.day], from: start, to: end).day ?? 0
    return days / 7
  }

  func onOrAfter(_ date: Date, _ md: MonthDay, _ year: Int) -> Date? {
    let current = monthDay(date)
    guard
      current.month > md.month
        || (current.month == md.month && current.day >= md.day)
    else { return nil }
    return date
  }

  func roman(_ value: Int) -> String {
    let table: [(Int, String)] = [
      (10, "X"), (9, "IX"), (5, "V"), (4, "IV"), (1, "I"),
    ]
    var remainder = value
    var result = ""
    for (amount, symbol) in table {
      while remainder >= amount {
        result += symbol
        remainder -= amount
      }
    }
    return result
  }

  // MARK: - Year anchors

  struct Anchors {
    let year: Int
    let epiphany: Date
    let septuagesima: Date
    let ashWednesday: Date
    let lent1: Date
    let palmSunday: Date
    let easter: Date
    let ascension: Date
    let whitsunday: Date
    let trinitySunday: Date
    let advent1: Date
    let nextAdvent1: Date

    init(year: Int, calendar: Calendar) {
      func make(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.year = y
        c.month = m
        c.day = d
        c.hour = 12
        return calendar.date(from: c)!
      }
      func shift(_ date: Date, _ days: Int) -> Date {
        calendar.date(byAdding: .day, value: days, to: date)!
      }
      func adventSunday(of y: Int) -> Date {
        // Fourth Sunday before Christmas: the Sunday on or after Nov 27.
        let nov27 = make(y, 11, 27)
        let weekday = calendar.component(.weekday, from: nov27)
        let offset = weekday == 1 ? 0 : 8 - weekday
        return shift(nov27, offset)
      }

      self.year = year
      let easterMD = OrdinariateCalendar.easter(year: year)
      let easterDate = make(year, easterMD.month, easterMD.day)
      epiphany = make(year, 1, 6)
      easter = easterDate
      septuagesima = shift(easterDate, -63)
      ashWednesday = shift(easterDate, -46)
      lent1 = shift(easterDate, -42)
      palmSunday = shift(easterDate, -7)
      ascension = shift(easterDate, 39)
      whitsunday = shift(easterDate, 49)
      trinitySunday = shift(easterDate, 56)
      advent1 = adventSunday(of: year)
      nextAdvent1 = adventSunday(of: year)
    }
  }
}
