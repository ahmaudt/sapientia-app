import Foundation

/// Pure formatting helpers for the Home "Your rules" rows and stats grid.
enum RuleRowMeta {

  static func metaString(
    appCount: Int,
    categoryCount: Int,
    strategyId: String?,
    isStrict: Bool,
    scheduleText: String?
  ) -> String {
    var parts: [String] = []

    parts.append(appCount == 1 ? "1 app" : "\(appCount) apps")
    if categoryCount > 0 {
      parts.append(categoryCount == 1 ? "1 category" : "\(categoryCount) categories")
    }

    let method = methodName(strategyId: strategyId)
    parts.append(method)

    if isStrict {
      parts.append("strict")
    } else if let scheduleText {
      parts.append(scheduleText)
    } else {
      parts.append(defaultTail(strategyId: strategyId))
    }

    return parts.joined(separator: " · ")
  }

  private static func methodName(strategyId: String?) -> String {
    guard let strategyId else { return "manual" }
    if strategyId.contains("NFC") { return "NFC tag" }
    if strategyId.contains("QR") { return "QR code" }
    if strategyId.contains("Timer") { return "timer" }
    return "manual"
  }

  private static func defaultTail(strategyId: String?) -> String {
    guard let strategyId else { return "until stopped" }
    if strategyId.contains("NFC") { return "until tapped out" }
    if strategyId.contains("QR") { return "until scanned out" }
    if strategyId.contains("Timer") { return "until timer ends" }
    return "until stopped"
  }
}

enum HomeStats {
  /// "12h 40m" / "12h" / "45m" / "0m"
  static func keptTimeString(_ interval: TimeInterval) -> String {
    let totalMinutes = Int(interval) / 60
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60
    switch (hours, minutes) {
    case (0, _): return "\(minutes)m"
    case (_, 0): return "\(hours)h"
    default: return "\(hours)h \(minutes)m"
    }
  }
}
