import Foundation

/// All copy shown on Screen Time shields, as pure functions. The shield
/// extension itself contains no copy decisions — everything here is
/// unit-testable from the app test target (the extension's own sources
/// are not reachable by tests, see plan).
enum ShieldContent {

  struct Shield: Equatable {
    let title: String
    let subtitle: String
    let buttonText: String
  }

  // MARK: - Prayer text (shared by shield, interstitial, previews)

  static func prayerText(
    prayer: BlockScreenPrayer,
    date: Date,
    calendar: OrdinariateCalendar = OrdinariateCalendar()
  ) -> (title: String, text: String) {
    if prayer == .collect {
      let day = calendar.day(for: date)
      if !day.collect.text.isEmpty {
        return ("Collect — \(day.dayName)", day.collect.text)
      }
    }
    return ("Prayer of St. Benedict", PrayerSettings.benedictPrayerText)
  }

  // MARK: - Prayer shield (standard blocks)

  static func prayerShield(
    prayer: BlockScreenPrayer,
    date: Date,
    blockedItemName: String,
    unblockPhrase: String,
    calendar: OrdinariateCalendar = OrdinariateCalendar()
  ) -> Shield {
    let blockedLine = "\(blockedItemName) is set aside \(unblockPhrase)."
    // prayerText falls back to St. Benedict on missing liturgical data —
    // the shield can never come up blank.
    let (title, text) = prayerText(prayer: prayer, date: date, calendar: calendar)
    return Shield(
      title: title,
      subtitle: "\(text)\n\n\(blockedLine)",
      buttonText: "Amen"
    )
  }

  /// How the block ends, phrased for the shield's closing line, derived
  /// from the profile's physical unblock items.
  static func unblockPhrase(hasNFCTag: Bool, hasQRCode: Bool) -> String {
    switch (hasNFCTag, hasQRCode) {
    case (true, _): return "until you tap your tag"
    case (false, true): return "until you scan your code"
    default: return "until the session ends"
    }
  }

  // MARK: - Soft-unblock shields

  static func allowanceIndicator(remaining: Int, maximum: Int) -> String {
    let available = Array(repeating: "●", count: max(remaining, 0))
    let used = Array(repeating: "○", count: max(maximum - remaining, 0))
    return (available + used).joined(separator: "  ")
  }

  static func softUnblockShield(
    resourceName: String,
    remaining: Int,
    maximum: Int,
    accessMinutes: Int,
    resetDescription: String?
  ) -> Shield {
    var lines = [
      "\(resourceName) (\(remaining)/\(maximum))",
      allowanceIndicator(remaining: remaining, maximum: maximum),
    ]
    if let resetDescription {
      lines.append(resetDescription)
    }
    return Shield(
      title: "Still set aside",
      subtitle: lines.joined(separator: "\n"),
      buttonText: "Open for \(accessMinutes)m"
    )
  }

  static func softUnblockExhausted(
    maximum: Int,
    resetDescription: String?
  ) -> Shield {
    let usageText =
      maximum == 1
      ? "You already used your open for this session."
      : "You used all \(maximum) opens for this session."
    let subtitle = [usageText, resetDescription]
      .compactMap { $0 }
      .joined(separator: " ")
    return Shield(title: "No opens left", subtitle: subtitle, buttonText: "Back")
  }
}
