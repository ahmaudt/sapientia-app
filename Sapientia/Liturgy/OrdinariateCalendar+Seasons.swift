import Foundation

// Season resolution for OrdinariateCalendar: maps a date within a
// liturgical year's anchors onto its named day, season, and collect key.
extension OrdinariateCalendar {

  // MARK: - Season resolution

  struct SeasonalDay {
    let dayName: String
    let season: LiturgicalSeason
    let collect: Collect
  }

  func seasonal(for date: Date, anchors: Anchors) -> SeasonalDay {
    // Advent → end of year
    if date >= anchors.advent1 {
      if let christmas = onOrAfter(date, MonthDay(month: 12, day: 25), anchors.year) {
        _ = christmas
        return christmastide(date, anchors: anchors)
      }
      return sundayCounted(
        date, start: anchors.advent1, prefix: "Advent", keyPrefix: "advent",
        season: .advent, maxIndex: 4)
    }

    // Jan 1 – Epiphany eve: still Christmastide (of the year-end before)
    if monthDay(date) < MonthDay(month: 1, day: 6) {
      return SeasonalDay(
        dayName: weekdayPrefixed(date, base: "Christmas II"),
        season: .christmastide,
        collect: keyedCollect("christmas2", title: "Christmas II"))
    }

    if date < anchors.septuagesima {
      // Epiphanytide: Sundays counted from the Epiphany (Jan 6)
      return sundayCounted(
        date, start: anchors.epiphany, prefix: "Epiphany", keyPrefix: "epiphany",
        season: .epiphanytide, maxIndex: 6, firstSundayIsIndexOne: true)
    }

    if date < anchors.ashWednesday {
      let names = ["Septuagesima", "Sexagesima", "Quinquagesima"]
      let index = weeksBetween(anchors.septuagesima, date)
      let name = names[min(index, 2)]
      return SeasonalDay(
        dayName: weekdayPrefixed(date, base: name),
        season: .preLent,
        collect: keyedCollect(name.lowercased(), title: name))
    }

    if date < anchors.lent1 {
      let isAshWednesdayItself = gregorian.isDate(date, inSameDayAs: anchors.ashWednesday)
      return SeasonalDay(
        dayName: isAshWednesdayItself
          ? "Ash Wednesday"
          : "\(weekdayName(date)) after Ash Wednesday",
        season: .lent,
        collect: keyedCollect("ashWednesday", title: "Ash Wednesday"))
    }

    if date < anchors.palmSunday {
      return sundayCounted(
        date, start: anchors.lent1, prefix: "Lent", keyPrefix: "lent",
        season: .lent, maxIndex: 5)
    }

    if date < anchors.easter {
      let base = "Palm Sunday"
      let name =
        isSunday(date)
        ? base
        : "\(weekdayName(date)) in Holy Week"
      return SeasonalDay(
        dayName: name,
        season: .holyWeek,
        collect: keyedCollect("palmSunday", title: "Palm Sunday"))
    }

    if date < anchors.whitsunday {
      if gregorian.isDate(date, inSameDayAs: anchors.easter) {
        return SeasonalDay(
          dayName: "Easter Day",
          season: .eastertide,
          collect: keyedCollect("easterDay", title: "Easter Day"))
      }
      if gregorian.isDate(date, inSameDayAs: anchors.ascension) {
        return SeasonalDay(
          dayName: "Ascension Day",
          season: .eastertide,
          collect: keyedCollect("ascension", title: "Ascension Day"))
      }
      if date > anchors.ascension {
        let base = "Sunday after Ascension"
        let governing = isSunday(date) ? date : previousSunday(date)
        let useSundayCollect = governing > anchors.ascension
        return SeasonalDay(
          dayName: isSunday(date) ? base : "\(weekdayName(date)) after Ascension",
          season: .eastertide,
          collect: keyedCollect(
            useSundayCollect ? "sundayAfterAscension" : "ascension",
            title: base))
      }
      return sundayCounted(
        date, start: anchors.easter, prefix: "Easter", keyPrefix: "easter",
        season: .eastertide, maxIndex: 5, firstSundayIsIndexOne: true)
    }

    if date < anchors.trinitySunday {
      return SeasonalDay(
        dayName: isSunday(date)
          ? "Whitsunday" : weekdayPrefixed(date, base: "Whitsun", style: .after),
        season: .whitsuntide,
        collect: keyedCollect("whitsunday", title: "Whitsunday"))
    }

    // Trinitytide
    return trinitytide(date, anchors: anchors)
  }

  func christmastide(_ date: Date, anchors: Anchors) -> SeasonalDay {
    // Dec 26–31 (Dec 25 itself is a principal feast in the sanctorale).
    return SeasonalDay(
      dayName: isSunday(date)
        ? "Christmas I"
        : weekdayPrefixed(date, base: "Christmas", style: .after),
      season: .christmastide,
      collect: keyedCollect("christmas", title: "Christmas Day"))
  }

  func trinitytide(_ date: Date, anchors: Anchors) -> SeasonalDay {
    let governingSunday = isSunday(date) ? date : previousSunday(date)
    let nextAdvent1 = anchors.nextAdvent1
    let isChristKing =
      gregorian.dateComponents([.day], from: governingSunday, to: nextAdvent1).day == 7

    if gregorian.isDate(governingSunday, inSameDayAs: anchors.trinitySunday) {
      return SeasonalDay(
        dayName: isSunday(date)
          ? "Trinity Sunday" : weekdayPrefixed(date, base: "Trinity Sunday", style: .after),
        season: .trinitytide,
        collect: keyedCollect("trinitySunday", title: "Trinity Sunday"))
    }

    if isChristKing {
      let base = "Christ the King"
      return SeasonalDay(
        dayName: isSunday(date) ? base : weekdayPrefixed(date, base: base, style: .after),
        season: .trinitytide,
        collect: keyedCollect("christTheKing", title: base))
    }

    let index = weeksBetween(anchors.trinitySunday, governingSunday)
    let base = "Trinity \(roman(index))"
    // Sundays beyond Trinity XXIV reuse the collects of the Sundays
    // omitted after Epiphany (traditional rule): XXV → Epiphany III, …
    let key = index <= 24 ? "trinity\(index)" : "epiphany\(index - 22)"
    return SeasonalDay(
      dayName: isSunday(date) ? base : weekdayPrefixed(date, base: base, style: .after),
      season: .trinitytide,
      collect: keyedCollect(key, title: base))
  }

  func sundayCounted(
    _ date: Date,
    start: Date,
    prefix: String,
    keyPrefix: String,
    season: LiturgicalSeason,
    maxIndex: Int,
    firstSundayIsIndexOne: Bool = false
  ) -> SeasonalDay {
    let governingSunday = isSunday(date) ? date : previousSunday(date)
    var index: Int
    if firstSundayIsIndexOne {
      // Sundays counted "after" a fixed day (the Epiphany): the first
      // Sunday strictly after `start` is index 1.
      let days = gregorian.dateComponents([.day], from: start, to: governingSunday).day ?? 0
      index = Int(ceil(Double(days) / 7.0))
    } else {
      index = weeksBetween(start, governingSunday) + 1
    }
    index = max(1, min(index, maxIndex))
    let base = "\(prefix) \(roman(index))"
    return SeasonalDay(
      dayName: isSunday(date) ? base : weekdayPrefixed(date, base: base, style: .after),
      season: season,
      collect: keyedCollect("\(keyPrefix)\(index)", title: base))
  }
}
