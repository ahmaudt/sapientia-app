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

    let feast = sanctoraleEntry(for: noon)
    let commemoration = feast.flatMap { entry in
      entry.rank == "commemoration" ? "Commemoration of \(entry.name)" : nil
    }

    let seasonalDay = seasonal(for: noon, anchors: anchors)

    // Principal feasts rename the day and provide its collect — except on
    // protected days (Holy Week, Easter Day, Sundays of Advent and Lent),
    // where the temporale always wins. Feast transfer is not modeled.
    let isProtected =
      seasonalDay.season == .holyWeek
      || seasonalDay.dayName == "Easter Day"
      || (isSunday(noon)
        && (seasonalDay.season == .advent || seasonalDay.season == .lent))

    if let principal = feast, principal.rank == "principal", !isProtected {
      return LiturgicalDay(
        dayName: principal.name,
        season: seasonalDay.season,
        commemorationText: nil,
        collect: Collect(
          title: principal.name,
          text: principal.collect ?? seasonalDay.collect.text)
      )
    }

    return LiturgicalDay(
      dayName: seasonalDay.dayName,
      season: seasonalDay.season,
      commemorationText: commemoration,
      collect: seasonalDay.collect
    )
  }


  // MARK: - Sanctorale

  private func sanctoraleEntry(for date: Date) -> LiturgicalDataset.Feast? {
    let md = monthDay(date)
    return dataset.sanctorale.first { $0.month == md.month && $0.day == md.day }
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
